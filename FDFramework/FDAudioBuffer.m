//----------------------------------------------------------------------------------------------------------------------------
//
// "FDAudioBuffer.m" - Sound playback.
//
// Written by:	Axel 'awe' Wefers			[mailto:awe@fruitz-of-dojo.de].
//				©2001-2012 Fruitz Of Dojo 	[http://www.fruitz-of-dojo.de].
//
//----------------------------------------------------------------------------------------------------------------------------

#import "FDAudioBuffer.h"
#import "FDAudioInternal.h"
#import "FDDefines.h"

#import <Cocoa/Cocoa.h>
#include <CoreAudio/CoreAudio.h>
#include <AudioToolbox/AudioToolbox.h>

//----------------------------------------------------------------------------------------------------------------------------

static OSStatus FDAudioBuffer_AudioUnitCallback (void*, AudioUnitRenderActionFlags*, const AudioTimeStamp*, UInt32, UInt32,
                                                 AudioBufferList*);

//----------------------------------------------------------------------------------------------------------------------------

@interface FDAudioBuffer()

- (NSUInteger) fillBuffer: (AudioBuffer*) pIoData;

@end

//----------------------------------------------------------------------------------------------------------------------------

@implementation FDAudioBuffer
{
@private
    FDAudioMixer*           mMixer;
    FDAudioBufferCallback   mpCallback;
    void*                   mpContext;
    AUNode                  mConverterNode;
    AudioUnitElement        mBusNumber;
}

- (instancetype) init
{
    self = [self initWithMixer:nil frequency:0 bitsPerChannel:0 channels:0 callback:NULL context:NULL];
    
    if (self != nil)
    {
        [self doesNotRecognizeSelector: _cmd];
    }
    
    return nil;
}

//----------------------------------------------------------------------------------------------------------------------------

- (instancetype) initWithMixer: (FDAudioMixer*) mixer
           frequency: (NSUInteger) frequency
      bitsPerChannel: (NSUInteger) bitsPerChannel
            channels: (NSUInteger) numChannels
            callback: (FDAudioBufferCallback) pCallback
             context: (void*) pContext
{
    self = [super init];
    
    if (self)
    {
        AUGraph     audioGraph      = 0;
        AudioUnit   converterUnit   = 0;
        Boolean     graphWasRunning = 0;
        OSStatus    err             = noErr - 1;
        
        if (mixer != nil)
        {
            mMixer      = mixer;
            mBusNumber  = [mixer allocateBus];
            audioGraph  = mixer.audioGraph;
            
            err = AUGraphIsRunning (audioGraph, &graphWasRunning);
        }
        
        if ((err == noErr) && graphWasRunning)
        {
            err = AUGraphStop (audioGraph);
        }
        
        if (err == noErr)
        {
            AudioComponentDescription	converterDesc = { 0 };
            
            converterDesc.componentType         = kAudioUnitType_FormatConverter;
            converterDesc.componentSubType      = kAudioUnitSubType_AUConverter;
            converterDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
        
            err = AUGraphAddNode (audioGraph, &converterDesc, &mConverterNode);
        }
        
        if (err == noErr)
        {
            err = AUGraphNodeInfo (audioGraph, mConverterNode, 0, &converterUnit);
        }

        if (err == noErr)
        {
            AURenderCallbackStruct  inCallback = { 0 };
            
            inCallback.inputProc            = FDAudioBuffer_AudioUnitCallback;
            inCallback.inputProcRefCon      = (__bridge void * _Nullable)(self);
        
            err = AudioUnitSetProperty (converterUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0,
                                        &inCallback, sizeof (inCallback));
        }
        
        if (err == noErr)
        {
            AudioStreamBasicDescription streamDesc      = { 0 };
            const UInt32                bytesPerFrame   = (UInt32) (numChannels * ( bitsPerChannel >> 3 ));
            const UInt32                framesPerPacket = 1;
            
            streamDesc.mSampleRate          = frequency;
            streamDesc.mFormatID            = kAudioFormatLinearPCM;
            streamDesc.mFormatFlags         = kLinearPCMFormatFlagIsPacked;
            streamDesc.mBytesPerPacket      = bytesPerFrame * framesPerPacket;
            streamDesc.mFramesPerPacket     = framesPerPacket;
            streamDesc.mBytesPerFrame       = bytesPerFrame;
            streamDesc.mChannelsPerFrame    = (UInt32) numChannels;
            streamDesc.mBitsPerChannel      = (UInt32) bitsPerChannel;
            
            if (bitsPerChannel > 8)
            {
                streamDesc.mFormatFlags |= kLinearPCMFormatFlagIsSignedInteger;
            }
            
            err = AudioUnitSetProperty (converterUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, 
                                        &streamDesc, sizeof (streamDesc));
        }
        
        if (err == noErr)
        {
            AUNode  mixerNode = mixer.mixerNode;
            
            err = AUGraphConnectNodeInput (audioGraph, mConverterNode, 0, mixerNode, mBusNumber);
        }
        
        if (err == noErr)
        {
            mpCallback  = pCallback;
            mpContext   = pContext;
        }

        if ((err == noErr) && graphWasRunning)
        {
            err = AUGraphStart (audioGraph);
        }        
        
        if (err != noErr)
        {
            return nil;
        }
    }
    
    return self;
}

//---------------------------------------------------------------------------------------------------------------------------

- (void) dealloc
{
    if (mMixer != nil)
    {
        AUGraph     audioGraph      = mMixer.audioGraph;
        AUNode      mixerNode       = mMixer.mixerNode;
        Boolean     graphWasRunning = false;
        
        AUGraphIsRunning (audioGraph, &graphWasRunning);
        
        if (graphWasRunning)
        {
            AUGraphStop (audioGraph);
        }
        
        AUGraphDisconnectNodeInput (audioGraph, mixerNode, mBusNumber);
        AUGraphRemoveNode (audioGraph, mConverterNode);
        
        if (graphWasRunning)
        {
            AUGraphStart (audioGraph);
        }
        
        [mMixer deallocateBus: mBusNumber];
        mMixer = nil;
    }
}


//----------------------------------------------------------------------------------------------------------------------------

- (void) setVolume: (float) volume
{
    [mMixer setVolume: volume forBus: mBusNumber];
}

//----------------------------------------------------------------------------------------------------------------------------

- (float) volume
{
    return [mMixer volumeForBus: mBusNumber];
}

//---------------------------------------------------------------------------------------------------------------------------

- (NSUInteger) fillBuffer: (AudioBuffer*) pIoData
{
    NSUInteger bytesToWrite = 0;
    
    if (mpCallback != nil)
    {
        bytesToWrite = (*mpCallback) (pIoData->mData, pIoData->mDataByteSize, mpContext);
    }

    return bytesToWrite;
}

@end

//----------------------------------------------------------------------------------------------------------------------------

static OSStatus FDAudioBuffer_AudioUnitCallback (void* pContext, AudioUnitRenderActionFlags* flags,
                                                 const AudioTimeStamp* pTime, UInt32 bus, UInt32 numFrames,
                                                 AudioBufferList* pIoData)
{
    FDAudioBuffer* pSound           = (__bridge FDAudioBuffer*) pContext;
    AudioBuffer*    pAudioBuffer    = &pIoData->mBuffers[0];
    NSUInteger      bytesToWrite    = pAudioBuffer->mDataByteSize;
    
    if (pSound)
    {
        bytesToWrite = [pSound fillBuffer: pAudioBuffer];
    }
    
    if (bytesToWrite != 0)
    {
        UInt8* pData = (UInt8*) pAudioBuffer->mData;
        
        FD_MEMSET (pData + pAudioBuffer->mDataByteSize - bytesToWrite, 0, bytesToWrite);
    }
    
    return noErr;
}

//----------------------------------------------------------------------------------------------------------------------------
