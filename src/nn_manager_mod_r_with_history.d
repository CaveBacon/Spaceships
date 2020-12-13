module nn_manager_mod_r_with_history;

import std.stdio;
import std.algorithm.comparison;
//import

import nn_manager;
import nn_manager_mod_reinforcement;
import record_keeper;
import record_history;

import and.api;
import and.platform;


class NNManagerModReinforcementWithHistory : NNManagerModReinforcement
{
	
	int _record_limit  = 2_000; //TODO: not magic number
	int _hist_num_inputs = 0;
	
	this(char[] filename, IActivationFunction actfn)
	{
		super(filename, actfn);
		_epoch_limit   = 50_000; //20_000;
	}
	
	
	override void make_training_data_internal(ref CompletedRecord record)
	{
		if (_ai.getResultFromRecord(record) == -1)
			return;
		//overriden so we don't do any duplicatio
		_training_input  ~= record.inputs;	
		_output_records  ~= _ai.getResultFromRecord(record);
		_training_scores ~= record.score; 
	}
	
	
	//TODO: this is much copy of pasta, could just make the part that calcs epochs its own function
	override void do_training(real[][] inputs, int[] output_records, real[] training_scores)
	{
		assert(inputs.length == output_records.length);
		
		if( inputs.length == 0 )
		{
			writeln("No Training Data for Neural Network!");
			return;
		}
		
		int epochs = max(inputs.length, _epoch_limit);
		/+to!int( epoch_factor / inputs.length );
		if (epochs == 0) epochs = 1=;+/
		writefln("Training Mod-Reinforcement Network With History, %d epochs, %d records", epochs, output_records.length);
		
		_backprop.setProgressCallback(&callback, 500 );
		
		_backprop.epochs = epochs;
		to!ModifiedReinforcementBackPropagation(_backprop).train(inputs, training_scores, output_records);
		writeln("done training");
	}
	
	//called when the file does not exist
	override void do_init(int num_inputs, int[] num_hidden_neurons_in_layer, int num_outputs)
	{
		_hist_num_inputs = num_inputs;
		
		super.do_init(num_inputs, num_hidden_neurons_in_layer, num_outputs);
	}
	
	//called when the file exists
	override bool load_net()
	{
		bool retval = super.load_net();
		//TODO: abstraction is leaking, badly!
		if(retval) 
		{
			_hist_num_inputs = _backprop.neuralNetwork.input.neurons.length;
		}
		return retval;
	}
	
	
	RecordHistory /+let's+/make_history()
	{
		char[] filename_no_ext;
		if(_filename[$-4..$] == ".txt")
		{
			filename_no_ext = _filename[0..$-4];
		} else {
			filename_no_ext = _filename;
			writeln("!!Hist. filename has no extension: %s", _filename); // this isn't an error, just a possible issue if it creates a filename collision with one of the AI files
		}
		
		assert("blah.txt"[$-4..$] == ".txt");
		
		writefln("init-ing History for %s", filename_no_ext);
		return new RecordHistory(to!string(filename_no_ext), _hist_num_inputs);
	}
	
	
	override void make_training_data(NNManagerBase opponent)
	{
		RecordHistory hist = make_history();
		// write completed records to file
		_record_keeper.write_records_to_history(hist);
		writeln("records written");
		// don't write opponent records to file, this could cause weird duplication errors
		/+opponent._record_keeper.write_records_to_history(_hist);+/
		// read from file
		writefln("reading records from history for %s", _filename);
		CompletedRecord[] records_from_history = [];
		int num_records_to_load = _record_limit - _record_keeper._completed_records.length;
		if(opponent !is null && g_train_on_opponent_records)
		{
			num_records_to_load -= opponent._record_keeper._completed_records.length;
		}
		num_records_to_load = max(num_records_to_load, 0); // trying to load values near MAX_INT when this went negative didn't work so great.
		hist.fill_array_to_n_records( records_from_history, num_records_to_load );
		
		writefln("making training data from this game (%s)", _filename);
		
		super.make_training_data(opponent);
		
		writefln("making training data from history %s", _filename);
		foreach(record ; records_from_history)
		{
			make_training_data_internal(record);
		}
		
		//_record_keeper.garbage_collect();
		hist.close();
		
	}
	
	override void adjust_NN_params()
	{
		super.adjust_NN_params();
		_backprop.learningRate = 0.05;//0.01;
		_backprop.errorThreshold = 0.05; //0.035; //determined experimentally to be smaller than the 0.05 for regular mod_r, but not take too long and be boring
	}
	
	
}