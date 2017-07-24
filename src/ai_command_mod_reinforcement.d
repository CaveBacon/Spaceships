module ai_command_mod_reinforcement;

/*
Copyright (c) 2017, Logan Freesh
All rights reserved.

See "License.txt"
*/



import std.file;

import ai_base;
import ai_base_mod_reinforcement;
import spaceships;
import unit;

import and.api;
import and.platform;


class ModifiedReinforcementCommandAI : ModifiedReinforcementBaseAI
{
	
	this( char[] filename, double time_window )
	{
		super(filename, time_window);
	}
	
	
	override void init_net()
	{
		int num_inputs = NUM_UNIT_TYPES * NUM_CAPTURE_POINTS * 4 + NUM_CAPTURE_POINTS * 2 + 3   //starting to smell like a funciton up in here.
			+ NUM_UNIT_TYPES + NUM_CAPTURE_POINTS + 1     // command_ai specific stuff
			+ 1 + NUM_UNIT_TYPES * 4 + NUM_CAPTURE_POINTS * 2   // gen2
			+ 2 // gen 2.5
            + NUM_CAPTURE_POINTS; // gen 3.5
			
		int num_outputs = NUM_CAPTURE_POINTS;
		int num_hidden_neurons = 144; // because I wanted it to be.
		
		
		do_init(num_inputs, num_hidden_neurons, num_outputs);	
		
	}
	
	
	override void configure_backprop()
	{
		void callback( uint currentEpoch, real currentError  )
		{
			writefln("Epoch: [ %s ] | Error [ %f ] ",currentEpoch, currentError );
		}
		_backprop.setProgressCallback(&callback, 100 );
		
		_backprop.epochs = 0;
		_backprop.learningRate = 0.01;
		_backprop.momentum = 0.2;
		_backprop.errorThreshold = 0.000001;
	}
}