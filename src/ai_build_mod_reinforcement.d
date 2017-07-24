module ai_build_mod_reinforcement;


/*
Copyright (c) 2017, Logan Freesh
All rights reserved.

See "License.txt"
*/


import std.file;

import ai_base;
import ai_base_mod_reinforcement;
import unit;
import factory_unit;
import spaceships;

import and.api;
import and.platform;


class ModifiedReinforcementBuildAI : ModifiedReinforcementBaseAI
{

	this( char[] filename, double time_window )
	{
		super(filename, time_window);
	}
	
	
	
	void weight_records(bool victory)
	{
		// make duplicate records for more expensive units.
		/+size_t training_len = _training_input.length;
		for(size_t i = 0; i < training_len; ++i)
		{
			UnitType unit_type = cast(UnitType)(_output_records[i]);  // cast(UnitType)nodeWinner(_output_records[i]) ;
			double unit_cost = get_unit_build_cost(unit_type);
			size_t num_dups = to!size_t( unit_cost / UNIT_COST_BASE ) - 1;
			for(size_t j = 0; j < num_dups; ++j)
			{
				_training_input    ~= _training_input[i];
				_training_output ~= _training_output[i]; 
			}
		}+/ 
	}
	
	
	override void init_net()
	{
			int num_inputs = NUM_UNIT_TYPES * NUM_CAPTURE_POINTS * 4 + NUM_CAPTURE_POINTS * 2 + 3
							 + NUM_UNIT_TYPES 
							 + NUM_CAPTURE_POINTS + 3 + NUM_UNIT_TYPES * 4 + NUM_CAPTURE_POINTS * 2   // gen2
							 + 2 // gen 2.5
                             + NUM_CAPTURE_POINTS; // gen 3.5
				
			int num_outputs = NUM_UNIT_TYPES;
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
		_backprop.learningRate = 0.02;
		_backprop.momentum = 0.2;
		_backprop.errorThreshold = 0.000001;
	}
	
	
	/+override int get_decision(real [] inputs)
	{
		assert
	}+/
	
	override void train_net(bool victory)
	{
		weight_records(victory);
		super.train_net(victory);
	}
	

}
