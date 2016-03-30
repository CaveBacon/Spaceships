module spaceships;


/*
Copyright (c) 2016, Logan Freesh
All rights reserved.

See "License.txt"
*/



import std.math;
import std.random;	
import std.stdio;
import std.conv;
import std.algorithm.mutation;
import std.typecons;
import std.file;
import std.array;

import core.memory;

import steering;
import collision;
import unit;
import factory_unit;
import capture_point;
import team;
import team_manual;
import ai_build;
import ai_command;
import matchinfo;

import dsfml.graphics;
import dsfml.system;


//TODO: put the teams, capture points, and unit/factory arrays in a Match object (so we could run more than one of them!)
// 

int NUM_CAPTURE_POINTS = 12;

//TOOD: deal with these better, some won't be needed
const Color steel_blue   = Color(0x46, 0x82, 0xB4);
const Color dark_green   = Color(0x00, 0x64, 0x00);
const Color forest_green = Color(0x22, 0x8B, 0x22);
//DarkSlateBlue  	#483D8B




struct NamedColor
{
	this(Color in_c, string in_n)
	{
		c = in_c;
		n = in_n;
	}
	
	this(ubyte r, ubyte g, ubyte b, string in_n)
	{
		c = Color(r,g,b);
		n = in_n;
	}
	
	Color  c;
	string n;
}

/+
NamedColor[]  AI_colors = [  NamedColor(0xFF, 0x00, 0x00, "Red")
							,NamedColor(0x46, 0x82, 0xB4, "SteelBlue") 
							];
	+/						

NamedColor[]  AI_colors = [  NamedColor(0xFF, 0x00, 0x00, "Red")
							,NamedColor(0x46, 0x82, 0xB4, "SteelBlue")
							,NamedColor(0x7F, 0xFF, 0x00, "Chartreuse")
							,NamedColor(0xFF, 0x7F, 0x50, "Coral")
							//,NamedColor(0x00, 0x64, 0x00, "DarkGreen")
							//,NamedColor(0xFF, 0x8C, 0x00, "DarkOrange")
							//,NamedColor(0x55, 0x6B, 0x2F, "DarkOliveGreen")
							,NamedColor(0x94, 0x00, 0xD3, "DarkViolet")
							//,NamedColor(0x00, 0xCE, 0xD1, "DarkTurquiose")
							,NamedColor(0xFF, 0x14, 0x93, "DeepPink")
							,NamedColor(0x40, 0x40 ,0x40, "▀▀▄▐▄█▀█▄▌█▀ ▌▌▌")
							];
							
							//NamedColor(0xDC, 0x14, 0x3C, "Crimson")


//this should go in an env object or something
TeamObj[] g_teams = [
					null,
					null,
					new TeamObj(TeamID.Neutral, Color.White, "Neutral" )
				 ];

RectangleShape[] g_ticket_bars = [
								   null,
								   null
  							     ];
								 
RectangleShape g_timer_bar;
				 
const double g_starting_tickets = 500.0;				 
				 
				 
bool g_is_manual_game = false; // TODO: this should be one of the parameters to run match.
				 
void main(string[] args)
{
    auto window = new RenderWindow(VideoMode(window_width,window_height),"AI: Artifical Idiocy");
	
	while( window.isOpen() )
	{
		if(args.length == 1)
			run_tourney(args, window);
		else
		if(args[1] == "play")
		{
			run_manual(args[2..$], window);
		} else if (args[1] == "tourney")
		{
			run_tourney(args[2..$], window);
		} else if(args[1] == "duel")
		{
			run_duel(args[2..$], window);
		} else if(args[1] == "nemesis")
		{
			run_duel_manual(args[2..$], window);
		} else 
		{
			run_tourney(args, window);
		}
		
		//g_teams[0] = new TeamObj(TeamID.One,     AI_colors[0].c , AI_colors[0].n);
		//g_teams[1] = new TeamObj(TeamID.Two,     AI_colors[1].c , AI_colors[1].n);
		//run_match(args, window);
		
		
	}
}

string TOURNEY_FILE = "nets\\_tourney_state.txt";

void run_tourney(string [] args, RenderWindow window)
{
	
	//load position
	string state_string = readText(TOURNEY_FILE);
	string[] iter_vals  = split(state_string,",");
	
	writefln("loaded state %s, %s", iter_vals[0], iter_vals[1]);
	
	for( int challenger = to!int(iter_vals[0]) ; challenger < AI_colors.length && window.isOpen(); ++challenger )
	{
		for( int opponent = to!int(iter_vals[1]) ; opponent < AI_colors.length && window.isOpen(); ++opponent )
		{
			if(challenger != opponent)
			{
				//save position
				std.file.write( TOURNEY_FILE, to!string(challenger) ~ "," ~ to!string(opponent) );
				
				if(g_teams[0] !is null) { destroy(g_teams[0]); }
				if(g_teams[1] !is null) { destroy(g_teams[1]); }
				
				g_teams[0] = new TeamObj(TeamID.One,     AI_colors[challenger].c , AI_colors[challenger].n);
				g_teams[1] = new TeamObj(TeamID.Two,     AI_colors[opponent  ].c , AI_colors[opponent  ].n);
				run_match(args, window);
				GC.collect();
			}
		}
		iter_vals[1] = "0";
		
	}
	
	// save poition 0,0 for next tourney
	if( window.isOpen() )
	{
		std.file.write( TOURNEY_FILE, "0,0" );
	}
}

void run_manual(string [] args, RenderWindow window)
{
	//"▀▀▄▐▄█▀█▄▌█▀ ▌▌▌" 
	
	g_is_manual_game = true;
	
	for( int opponent = 0 ; opponent < AI_colors.length && window.isOpen(); ++opponent )
	{
	
		if(g_teams[0] !is null) { destroy(g_teams[0]); }
		if(g_teams[1] !is null) { destroy(g_teams[1]); }
		
		PlayerTeam pt = new PlayerTeam(TeamID.One,     forest_green            , "▀▀▄▐▄█▀█▄▌█▀ ▌▌▌"   );
		g_teams[0]    = pt;
		g_teams[1]    = new TeamObj   (TeamID.Two,     AI_colors[opponent  ].c , AI_colors[opponent].n);
		
		pt.set_window(window);
		run_match(args, window);
		GC.collect();
	
	}
}


void run_duel(string [] args, RenderWindow window)
{	
	g_is_manual_game = false;
	
	while(window.isOpen())
	{
		int player_1 = to!int(args[0]);
		int player_2 = to!int(args[1]);
		
		if(g_teams[0] !is null) { destroy(g_teams[0]); }
		if(g_teams[1] !is null) { destroy(g_teams[1]); }
		
		g_teams[0]    = new TeamObj(TeamID.One,     AI_colors[player_1].c , AI_colors[player_1].n);
		g_teams[1]    = new TeamObj(TeamID.Two,     AI_colors[player_2].c , AI_colors[player_2].n);
		
		run_match(args[2..$], window);
		GC.collect();
	
	}
}

void run_duel_manual(string [] args, RenderWindow window)
{
	//"▀▀▄▐▄█▀█▄▌█▀ ▌▌▌" 
	
	g_is_manual_game = true;
	
	while(window.isOpen())
	{
		int opponent =  to!int(args[0]);
		
		if(g_teams[0] !is null) { destroy(g_teams[0]); }
		if(g_teams[1] !is null) { destroy(g_teams[1]); }
		
		PlayerTeam pt = new PlayerTeam(TeamID.One,     forest_green            , "▀▀▄▐▄█▀█▄▌█▀ ▌▌▌"   );
		g_teams[0]    = pt;
		g_teams[1]    = new TeamObj   (TeamID.Two,     AI_colors[opponent  ].c , AI_colors[opponent].n);
		
		pt.set_window(window);
		run_match(args[1..$], window);
		GC.collect();
	
	}
}


void run_match(string [] args, RenderWindow window)
{
	
	auto waypoint = new RectangleShape(Vector2f(4,4));
	waypoint.fillColor = Color.White;
	waypoint.position = Vector2f(window_width/2,window_height/2);
	
	// make a clock
	Clock the_clock = new Clock();
	
	// make some dots
	Unit[] dots;
	FactoryUnit[] factories;
	CapturePoint[] capture_points;
	
	double game_timer = 0.0;
	double game_time_limit = 750.0;
	bool   game_over = false;
	double game_speed = 10.0;
	bool allow_overtime = false;
	
	g_teams[0].set_opponent(g_teams[1]);
	g_teams[1].set_opponent(g_teams[0]);
	writeln("opponents are set");
	
	////////////////////////////////////
	//Handle args and make initial units
	////////////////////////////////////
	if(args.length >= 1)
	{
		game_speed = to!double(args[0]);
	}
	
	if(args.length >= 2)
	{
		game_time_limit = to!double(args[1]);
	}
	
	while(args.length < 11)
	{
		args ~= "0";
	}
	
	int num_red_fighters   = to!int(args[2]);
	int num_red_lightships = to!int(args[3]);
	int num_red_bigships   = to!int(args[4]);
	int num_red_mthrships  = to!int(args[5]); 
	int num_blu_fighters   = to!int(args[6]);
	int num_blu_lightships = to!int(args[7]);
	int num_blu_bigships   = to!int(args[8]);
	int num_blu_mthrships  = to!int(args[9]);
	
	g_unit_count = 0;
	
	
	for( int i = 0; i < num_red_fighters   ; ++i )
	{
		dots ~= make_unit(UnitType.Interceptor, g_teams[0], g_teams[0]._color, uniform(0.0,window_width/2), uniform(0.0,window_height));
	}
	for( int i = 0; i < num_red_lightships ; ++i )
	{
		dots ~= make_unit(UnitType.Corvette   , g_teams[0], g_teams[0]._color, uniform(0.0,window_width/2), uniform(0.0,window_height));
	}
	for( int i = 0; i < num_red_bigships   ; ++i )
	{
		dots ~= make_unit(UnitType.Battleship , g_teams[0], g_teams[0]._color, uniform(0.0,window_width/2), uniform(0.0,window_height));
	}
	for( int i = 0; i < num_red_mthrships  ; ++i )
	{
		FactoryUnit factory1 = cast(FactoryUnit)make_unit(UnitType.Mothership, g_teams[0], g_teams[0]._color, uniform(0.0,window_width/2), uniform(0.0,window_height));
		dots ~= factory1;
		factories ~= factory1;
	}
	
	for( int i = 0; i < num_blu_fighters   ; ++i )
	{
		dots ~= make_unit(UnitType.Interceptor, g_teams[1], g_teams[1]._color, uniform(window_width/2,window_width), uniform(0.0,window_height));
	}
	for( int i = 0; i < num_blu_lightships ; ++i )
	{
		dots ~= make_unit(UnitType.Corvette   , g_teams[1], g_teams[1]._color, uniform(window_width/2,window_width), uniform(0.0,window_height));
	}
	for( int i = 0; i < num_blu_bigships  ; ++i )
	{
		dots ~= make_unit(UnitType.Battleship , g_teams[1], g_teams[1]._color, uniform(window_width/2,window_width), uniform(0.0,window_height));
	}
	for( int i = 0; i < num_blu_mthrships  ; ++i )
	{
		FactoryUnit factory1 = cast(FactoryUnit)make_unit(UnitType.Mothership, g_teams[1], g_teams[1]._color, uniform(window_width/2,window_width), uniform(0.0,window_height));
		dots ~= factory1;
		factories ~= factory1;
	}
	
	const double cap_radius = 100.0;
	const double cap_placement_scale = 125;
	int count = 0;
	capture_points ~= new CapturePoint(cap_placement_scale*1.0, cap_placement_scale*1.0, cap_radius, count++);
	capture_points[$-1].set_team( TeamID.One );
	
	capture_points ~= new CapturePoint(cap_placement_scale*4.0, cap_placement_scale*1.0, cap_radius, count++);
	capture_points ~= new CapturePoint(cap_placement_scale*2.5, cap_placement_scale*2.5, cap_radius, count++);
	capture_points ~= new CapturePoint(cap_placement_scale*1.0, cap_placement_scale*4.0, cap_radius, count++);
	
	capture_points ~= new CapturePoint(cap_placement_scale*6.5, cap_placement_scale*1.5, cap_radius, count++);
	capture_points ~= new CapturePoint(cap_placement_scale*5.0, cap_placement_scale*3.0, cap_radius, count++);
	capture_points ~= new CapturePoint(cap_placement_scale*3.0, cap_placement_scale*5.0, cap_radius, count++);
	capture_points ~= new CapturePoint(cap_placement_scale*1.5, cap_placement_scale*6.5, cap_radius, count++);
	
	capture_points ~= new CapturePoint(cap_placement_scale*7.0, cap_placement_scale*4.0, cap_radius, count++);
	capture_points ~= new CapturePoint(cap_placement_scale*5.5, cap_placement_scale*5.5, cap_radius, count++);
	capture_points ~= new CapturePoint(cap_placement_scale*4.0, cap_placement_scale*7.0, cap_radius, count++);
	
	capture_points ~= new CapturePoint(cap_placement_scale*7.0, cap_placement_scale*7.0, cap_radius, count++);
	capture_points[$-1].set_team( TeamID.Two );
	
	Vector2d battlefield_size = Vector2d(cap_placement_scale*8.0, cap_placement_scale*8.0);
	
	CollisionGrid grid = new CollisionGrid( Vector2d(cap_placement_scale*0.5, cap_placement_scale*0.5),
											battlefield_size + Vector2d(cap_placement_scale, cap_placement_scale),
											30, 30 );
											
											
	MatchInfo minfo = MatchInfo( battlefield_size, game_time_limit, g_starting_tickets, NUM_CAPTURE_POINTS );
	
	g_teams[0].set_points(capture_points);
	g_teams[1].set_points(capture_points);
	
	g_teams[0].set_factory_array(&factories);
	g_teams[1].set_factory_array(&factories);
	
	g_teams[0].set_match_info(minfo);
	g_teams[1].set_match_info(minfo);
	
	FactoryUnit factory1 = cast(FactoryUnit)make_unit(UnitType.Mothership, g_teams[0], g_teams[0]._color, cap_placement_scale*1.0, cap_placement_scale*1.0, g_is_manual_game );
		dots      ~= factory1;
		factories ~= factory1;
	factory1             = cast(FactoryUnit)make_unit(UnitType.Mothership, g_teams[1], g_teams[1]._color, cap_placement_scale*7.0, cap_placement_scale*7.0);
		dots      ~= factory1;
		factories ~= factory1;
	
	
	g_teams[0].set_ai_input_display(  Vector2f(window.size.x - 200, 100) ); // use display size?
	g_teams[1].set_ai_input_display(  Vector2f(window.size.x - 300, 100) ); // use display size?
	
	g_ticket_bars[0] = new RectangleShape(Vector2f(0,20));
	g_ticket_bars[1] = new RectangleShape(Vector2f(0,20));
	g_ticket_bars[0].fillColor = g_teams[0]._color;
	g_ticket_bars[1].fillColor = g_teams[1]._color;
	
	g_timer_bar = new RectangleShape( Vector2f( 50.0f , 30.0f ) );
	g_timer_bar.fillColor = Color.White;
	
	/+foreach(dot; dots[0..20])
	{
		dot._disp.fillColor = Color(255,100,0);
	}+/
	
	writeln("'bout that time, eh chaps?");
	Time now      = the_clock.getElapsedTime();
	Time previous = the_clock.getElapsedTime();
	writeln("Righto.");
	
    while( window.isOpen() && !game_over )
    {
		//writeln("loopin'");
        Event event;

        while(window.pollEvent(event))
        {
            if(event.type == event.EventType.Closed)
            {
                window.close();
            }
        }
		
		if(Keyboard.isKeyPressed(Keyboard.Key.LAlt) || Keyboard.isKeyPressed(Keyboard.Key.RAlt) ) 
		{
		
			if( Keyboard.isKeyPressed(Keyboard.Key.End) )
			{
				g_teams[0].handle_endgame(false);
				g_teams[1].handle_endgame(false);
			}
			
			if( Keyboard.isKeyPressed(Keyboard.Key.Home) )
			{
				allow_overtime = true;
			}
			
			if( Keyboard.isKeyPressed(Keyboard.Key.Num1) || Keyboard.isKeyPressed(Keyboard.Key.Numpad1) )
			{
				g_teams[1].handle_endgame(false);
				g_teams[0].handle_endgame(true);
			}
			
			if( Keyboard.isKeyPressed(Keyboard.Key.Num2) || Keyboard.isKeyPressed(Keyboard.Key.Numpad2) )
			{
				g_teams[0].handle_endgame(false);
				g_teams[1].handle_endgame(true);
			}
		
		}
		
		if (Mouse.isButtonPressed(Mouse.Button.Left))
		{
			// left mouse button is pressed: set dest
			Vector2i mouse_pos = Mouse.getPosition(window);
			if( mouse_pos.x >= 0 && mouse_pos.x <= window_width &&
				mouse_pos.y >= 0 && mouse_pos.y <= window_height   )
			{			
				/+foreach(dot; dots)
				{
					if(dot._team._id == TeamID.One)
					{
						dot._destination = mouse_pos;
					}
				}+/
				waypoint.position = Vector2f(mouse_pos.x, mouse_pos.y);
			}
		}
		
		
		now = the_clock.getElapsedTime();
		double dt = (now - previous).asMicroseconds() / 1000000.0; // number of seconds since last update as double
		previous = now;
		const double dt_max = 1.0/30.0;
		if(dt > dt_max) dt = dt_max;
		dt *= game_speed;
		game_timer += dt;
		if(game_timer > game_time_limit && !allow_overtime)
		{
			g_teams[0].handle_endgame(false);
			g_teams[1].handle_endgame(false);
		}
		//writefln("dt= %f", dt);
		
		
		//team_incomes[] = 20.0;
		
		//////////////////////
		// Update Everything!
		//////////////////////
		
		grid.update( dots );
		
		
		foreach(point; capture_points)
		{
			point.update( grid , dt);
			//team_incomes[point._team] += 20.0; 
		}
		
		foreach(dot; dots)
		{
			dot.unit_update( grid , dt);
			//TODO: unit should just handle this itself
			if(dot._needs_orders && !dot._player_controlled)
			{
				dot.get_orders();
				dot._destination = capture_points[dot._destination_id]._pos;
				
			}
		}
		
		
		
		foreach(team ; g_teams[0..2])
		{
			team.update(grid, dt);
		}
		
		foreach(factory ; factories)
		{ 
			Unit produced = factory.give_resources(factory._team._income_per_factory * dt);
			if(produced !is null)
			{
				dots ~= produced;
				if(produced._type == UnitType.Mothership )
				{
					factories ~= cast(FactoryUnit) produced;
					writeln("adding a factory");
				}
			}
		}
		
		
		//draw everything
        window.clear();
		
		foreach(dot; dots)
		{
			window.draw(dot);
		}
		foreach(point; capture_points)
		{
			window.draw(point); 
		}
		
		foreach(team; g_teams)
		{
			window.draw(team);
		}
		
		/+int[] dead_things;
		foreach(dot, i; dots)
		{
			if(dot.is_dead())
			{
				dead_things ~= i;//do dome splicing to remove it from dots
			}
		}+/
		//remove any dead dots
		dots = remove!("a.is_dead()")(dots);
		factories = remove!("a.is_dead()")(factories);
		
		game_over = g_teams[0]._game_over || g_teams[1]._game_over;
		
		//writefln("%d dots left",dots.length);
		
		//window.draw(waypoint);
		
		draw_ticket_bars(window);
		draw_timer_bar  (window, game_time_limit, game_timer);
		
        window.display();
    }
	
	g_teams[0].cleanup_ais();
	g_teams[1].cleanup_ais();
	g_teams[2].cleanup_ais();
	
	
	
}



void draw_ticket_bars( RenderTarget surface )
{
	float total_width = surface.getSize().x;
	float midpoint = total_width/2.0;
	
	//writefln("midpoint %f", midpoint);
	//writefln("%f",midpoint * g_teams[0]._tickets / g_starting_tickets);
	
	g_ticket_bars[0].size( Vector2f( g_ticket_bars[0].size.x = midpoint * g_teams[0]._tickets / g_starting_tickets, 30.0f ));
	g_ticket_bars[1].size( Vector2f( g_ticket_bars[1].size.x = midpoint * g_teams[1]._tickets / g_starting_tickets, 30.0f ));
	
	//writefln("width %f", g_ticket_bars[0].size.x);
	
	g_ticket_bars[0].position( Vector2f( midpoint - g_ticket_bars[0].size.x, 0 ));
	g_ticket_bars[1].position( Vector2f( midpoint                          , 0 ));
	
	
	if ( g_teams[0]._tickets > 0 )
	{
		surface.draw(g_ticket_bars[0]);
	} 
		
	
	if ( g_teams[1]._tickets > 0 )
	{
		surface.draw(g_ticket_bars[1]);
	}
	
}


void draw_timer_bar( RenderTarget surface, double time_limit, double game_timer )
{
	
	double time_left = time_limit - game_timer;
	
	float bar_full_height = surface.getSize().y - 30.0f;
	
	float bar_draw_height = bar_full_height * time_left / time_limit;
	
	g_timer_bar.size = Vector2f( 40.0f , bar_draw_height  );
	
	g_timer_bar.position = Vector2f( surface.getSize().x - 50.0f , 30.0f );
	
	surface.draw(g_timer_bar);
	
}


/+
int get_command()
{
	//temptemptemp
	return to!int(floor(uniform01() * 12));
}
	
int get_build_order()
{
	//temptemptemp
	return dice(18,18,18,3,3,3,1,1,1);
}
+/