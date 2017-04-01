/*
Wraps Ken Loveday's MicroLibrary to provide easy access from AutoHotkey (Or other languages)

Aims to provide a low CPU usage way to sleep from 1-10 ms
Pass it a callback and a frequency, and it fires the callback at that frequency

fireImmediately can be set to true to fire the callback once straight away
ms value can be negative to have the callback only fire once
*/
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

public class MicroTimer
{
    public Timer Create(dynamic handler, int ms, bool fireImmediately = false)
    {
        return new Timer(handler, ms, fireImmediately);
    }

    public class Timer
    {
        private int tickTime;
        private bool state = false;
        private bool singleTick = false;
        private dynamic Callback;
        private MicroLibrary.MicroTimer microTimer = new MicroLibrary.MicroTimer();

        public Timer(dynamic handler, int ms, bool fireImmediately = false)
        {
            microTimer.MicroTimerElapsed +=
                new MicroLibrary.MicroTimer.MicroTimerElapsedEventHandler(OnTimedEvent);

            Callback = handler;

            if (ms < 0)
            {
                singleTick = true;
                ms = Math.Abs(ms);
            }
            tickTime = ms * 1000;
            microTimer.Interval = tickTime; // Convert from ms to µs

            // Can choose to ignore event if late by Xµs (by default will try to catch up)
            //microTimer.IgnoreEventIfLateBy = 500; // 500µs (0.5ms)

            if (fireImmediately)
                Callback();
        }

        // provide an easy way to implement toggles by flipping an int between 1 and 0 (var := !var in AHK)
        public bool SetState(int state)
        {
            if (state == 0)
                return Stop();
            else 
                return Start();
        }

        public bool Start()
        {
            if (!state)
            {
                state = true;
                microTimer.Enabled = state; // Start timer
                return true;
            }
            return false; 
        }

        public bool Stop()
        {
            if (state)
            {
                state = false;
                microTimer.Enabled = state; // Stop timer (executes asynchronously)
                return true;
            }
            return false;
        }

        private void OnTimedEvent(object sender, MicroLibrary.MicroTimerEventArgs timerEventArgs)
        {
            Callback();
            if (singleTick)
                Stop();
            //// Do something small that takes significantly less time than Interval
            //Console.WriteLine(string.Format(
            //    "Count = {0:#,0}  Timer = {1:#,0} µs, " +
            //    "LateBy = {2:#,0} µs, ExecutionTime = {3:#,0} µs",
            //    timerEventArgs.TimerCount, timerEventArgs.ElapsedMicroseconds,
            //    timerEventArgs.TimerLateBy, timerEventArgs.CallbackFunctionExecutionTime));
        }
    }
}