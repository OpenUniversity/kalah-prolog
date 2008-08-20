/***********************************************************************
	Program	:	Kalah game in PROLOG
	Written by	:	Ken Egozi
	File		:	moves.pl
	Description	:	moving between states
***********************************************************************/


opposite_pit(PitNo, OppositePitNo) :-
	is_kalah(KalahPitNo),
	OppositePitNo is KalahPitNo - PitNo.

is_empty_pit(player1, P1Pits/_, PitNo) :- !,
	ArgNo is PitNo + 1,
	arg(ArgNo, P1Pits, 0), !.

is_empty_pit(player2, _/P2Pits, PitNo) :- !,
	ArgNo is PitNo + 1,
	arg(ArgNo, P2Pits, 0), !.
 

empty_pit(Pits, PitNo, Seeds, NewPits) :-
	Pits =.. PitsList,
	NodeNo is PitNo + 2,
	pop_from_index(PitsList, NodeNo, NewPitsList, Seeds),
	NewPits =.. NewPitsList.


%select_pit(Pos, MoveData, Pos1),
select_pit(Turn/P1Pits/P2Pits, Turn-PitNumber/SeedsInHand, Turn/P1Pits1/P2Pits1) :-
	(Turn=player1,!,
		select_pit(P1Pits, PitNumber/SeedsInHand, P1Pits1),
		P2Pits1 = P2Pits
	;
		select_pit(P2Pits, PitNumber/SeedsInHand, P2Pits1),
		P1Pits1 = P1Pits
	).	

select_pit(Pits, PitNumber/SeedsInHand, Pits1) :-
	pits(P),
	in_range(PitNumber, 1-P),
	empty_pit(Pits, PitNumber, SeedsInHand, Pits1),
	SeedsInHand > 0.


moves( Pos, PosList) :-
	bagof(P, move(Pos, P), PosList).
move(Pos, NewPos-PitNumber/SeedsInHand/Special) :-
	select_pit(Pos, Turn-PitNumber/SeedsInHand, InitialPos),
	step(InitialPos, Turn/PitNumber, SeedsInHand, Pos1, LastBoard/LastPitNumber),
	post_move(Pos1, LastBoard,LastPitNumber, Turn, NewPos, Special).

post_move(Pos1, _,LastPitNumber, Turn, NewPos, Special):-
	is_kalah(LastPitNumber),!,
	Special=kalah(Turn),
	(player2_has_moves(Pos1),!,
		Pos1 = NewPos		
	;
		next_player(Pos1, NewPos)
	).

post_move(Pos1, LastBoard,LastPitNumber, _, NewPos, Special):-
	(collect(Pos1, LastBoard/LastPitNumber, Pos2, Special),!
	;
		Pos2=Pos1
	),
	next_player(Pos2, NewPos).

/**/

collect(Turn/P1/P2, LastBoard/LastPitNumber, Turn/P11/P21, special(Turn/LastPitNumber/Seeds/OppositePitNo/SeedsInOppositePit)) :-
	LastBoard=Turn,!,
	not is_kalah(LastPitNumber),!,
	opposite_pit(LastPitNumber, OppositePitNo),
	(Turn=player1,!,
		empty_pit(P2, OppositePitNo, SeedsInOppositePit, Emptied),
		P2_Temp=Emptied,
		P1_Temp=P1
	;
		empty_pit(P1, OppositePitNo, SeedsInOppositePit, Emptied),
		P2_Temp=P2,
		P1_Temp=Emptied
	),
	SeedsInOppositePit > 0,!,
	collect(Turn/P1_Temp/P2_Temp, Turn/LastPitNumber, Seeds, SeedsInOppositePit, Turn/P11/P21).
	
collect(Turn/P1/P2, Turn/LastPitNo, SeedsInPit, SeedsInOppositePit, Turn/P11/P21) :-
	(Turn=player1,!,
		empty_pit(P1, LastPitNo, SeedsInPit, Emptied),
		ToAdd is SeedsInPit + SeedsInOppositePit,
		add_to_kalah(Emptied, ToAdd, P11),
		P21 = P2
	;
		empty_pit(P2, LastPitNo, SeedsInPit, Emptied),
		ToAdd is SeedsInPit + SeedsInOppositePit,
		add_to_kalah(Emptied, ToAdd, P21),
		P11 = P1
	).


% step/5
% step(Pos, From, Seeds, NewPos, To)
% putting the Seeds taken from pit From into the board,
% ending with NewPos, where To is the last pit that got a seed
step(Turn/P1Pits/P2Pits, From, 0, Turn/P1Pits/P2Pits, From) :- !.
step(Turn/P1Pits/P2Pits, CurrentPlayerBoard/TakenFrom, SeedsInHand, Turn/NewP1Pits/NewP2Pits, LastPlayerBoard/LastPitNo) :-
	StartAt is TakenFrom + 1,
	next_player(CurrentPlayerBoard, NextPlayerBoard),
	(CurrentPlayerBoard=player1, !,
		put_seeds(Turn, P1Pits, StartAt, SeedsInHand, P1Pits1, LastPitNo1, SeedsLeft),
		P2Pits1=P2Pits
	;
		put_seeds(Turn, P2Pits, StartAt, SeedsInHand, P2Pits1, LastPitNo1, SeedsLeft),
		P1Pits1=P1Pits
	),
	(SeedsLeft=0, !,
		NewP1Pits=P1Pits1 ,NewP2Pits=P2Pits1,
		LastPlayerBoard=CurrentPlayerBoard, LastPitNo=LastPitNo1
	;
		step(Turn/P1Pits1/P2Pits1, NextPlayerBoard/0, SeedsLeft, Turn/NewP1Pits/NewP2Pits, LastPlayerBoard/LastPitNo)
	).
	
% put_seeds/7
% put_seeds(Turn, Pits, StartAt,SeedsInHand,NewPits, LastPitNo, SeedsLeft).
put_seeds(Turn, Pits, StartAt, SeedsInHand, NewPits, LastPitNo, SeedsLeft) :-
	Pits =.. [pits|PlayerAndPitsList],
	len(PlayerAndPitsList, Length),
	PlayerAndPitsList = [Player|_],
	(Player = Turn,!, Max=Length ; Max is Length - 1),
	PitsLeft is Max - StartAt,
	(SeedsInHand =< PitsLeft, !,
		SeedsLeft = 0,
		ToAdd = SeedsInHand
	;
		ToAdd = PitsLeft,
		SeedsLeft is SeedsInHand - PitsLeft
	),		
	LastPitNo is StartAt + ToAdd - 1,
	copy_list_and_add(PlayerAndPitsList, StartAt, ToAdd, PlayerAndPitsList1),
	NewPits =.. [pits|PlayerAndPitsList1].


% move a single step in a move - putting a seed from the player's
% hand into the next pit.
	
	% determine collect
	% determine ended_in_kalah->free_move
step(Turn/P1Pits/P2Pits, LastPit, SeedsInHand, Turn/NewP1Pits/NewP2Pits, NewPit, NewSeedsInHand) :-
	next_pit(Turn, LastPit, NewPitPlayer/NewPitNo),
	SeedsInHand1 is SeedsInHand - 1,
	(
		NewPitPlayer = player2,!,
		add_seed_to_pit(P2Pits, NewPitNo, NewP2Pits),
		Board1 = P1Pits/NewP2Pits
	;
		add_seed_to_pit(P1Pits, NewPitNo, NewP1Pits),
		Board1 = NewP1Pits/P2Pits
	),
	step(Turn/Board1, NewPitPlayer/NewPitNo, SeedsInHand1, Turn/NewP1Pits/NewP2Pits, NewPit, NewSeedsInHand).

% determine the next pit that a seed should go into
% will be the next player's pit, or his kalah after the last pit,
% or the first pit of the oponent's after the player's kalah
next_pit(Turn, LastPitPlayer/LastPitNo, NextPitPlayer/NextPitNo) :-
	pits(PitsPerPlayer),
	(
		Turn = LastPitPlayer, !, 
		MaxPitNo is PitsPerPlayer + 1
	;
		MaxPitNo is PitsPerPlayer
	),
	(
		LastPitNo is MaxPitNo, !, 
		next_player(LastPitPlayer, NextPitPlayer),
		NextPitNo = 1
	;
		NextPitPlayer = LastPitPlayer,
		NextPitNo is LastPitNo + 1
	)
	.

% will add N seeds to the kalah of Pits
add_to_kalah(Pits, N, NewPits) :-
	Pits =.. PitsList,
	add_to_last(PitsList, N, NewPitsList),
	NewPits =.. NewPitsList.


% switching players. straightforward
next_player(Turn/P1/P2, NextTurn/P1/P2):-
	next_player(Turn, NextTurn).

next_player(player1, player2).
next_player(player2, player1).

% huristic function to evaluate board
% positive values -> player 2 is winning, while negative values mean player 1 is winning
h(_/P1Pits/P2Pits, Val) :- 
	pits(PitsPerPlayer),!,
	KalahIndex is PitsPerPlayer + 2,
	arg(KalahIndex, P1Pits, P1Kalah),
	arg(KalahIndex, P2Pits, P2Kalah),!,
	pits(Size),
	EnoughToWin is Size^2 + 1,
	(P1Kalah >= EnoughToWin,!,
		Val is 0 - 3000
	;
		(P2Kalah >= EnoughToWin,!,
			Val=3000
		;
			Val is P2Kalah - P1Kalah
		)
	).
	

%determine current player
min_to_move(player1/_/_-_).
max_to_move(player2/_/_-_).

turn(Player) :-
	pos(Player/_/_).

%determine if the pit numbered K is the kalah
is_kalah(K) :-
	pits(P),
	K is P + 1.

player1_move(PitNo) :-
	pos(Pos),
	(select_pit(Pos, player1-PitNo/SeedsInHand, InitialPos),!,
		step(InitialPos, player1/PitNo, SeedsInHand, Pos1, LastBoard/LastPitNumber),
		(is_kalah(LastPitNumber),!,
			set_pos(Pos1),
			set_special(kalah(player1)),
			set_game_state(player1_kalah)
		;
			(collect(Pos1, LastBoard/LastPitNumber, Pos2, Special),!,
				set_special(Special),
				set_game_state(player1_collect)
			;
				Pos2=Pos1
			),
			next_player(Pos2, NewPos),
			set_pos(NewPos)
		)
	;
		set_game_state(no_move)
	),
	highlight_special.


play(player2):-
	pos(Pos),
	depth(Depth),
	alphabeta( Pos, -3000, +3000, GoodPosWithMeta, _, Depth),
	(var(GoodPosWithMeta),!,
		set_game_state(player2_nomove)
	;
		GoodPosWithMeta=GoodPos-PitPlayed/SeedsInPit/Special,
		set_pit_played(PitPlayed/SeedsInPit),
		set_special(Special),
		set_pos(GoodPos)
	).


game_over :-
	game_state(game_over),!.

game_over :-
	pos(_/P1/P2),
	P1=..[pits,_|P1PitsList],
	P2=..[pits,_|P2PitsList],
	are_all_pits_zeros(P1PitsList),
	are_all_pits_zeros(P2PitsList).
	
	
play:-
	game_over,!,
	set_game_state(game_over),
	show_game_over_message.

play:-
	turn(player1),!,
	add_message(`Your turn ...`),
	show_messages,
	sleep(1000),
	(player1_has_moves,!,
		set_game_state(waiting)
	;
		turn_over,
		add_message(`No more moves, turn over.`),
		play
	).

play:-
	turn(player2),!,
	add_message(`Computer's turn ...`),
	show_messages,
	sleep(1000),
	(player2_has_moves,!,
		play(player2),
		highlight_played_pit,
		highlight_special,
		draw_all_pits
	;
		add_message(`No more moves, turn over.`),
		turn_over
	),
	play.

player1_has_moves:-
	pos(_/P1/_),
	P1=..[pits,_|P1PitsList],
	(are_all_pits_zeros(P1PitsList),!,fail;true).
player2_has_moves:-
	pos(Pos),
	player2_has_moves(Pos).
player2_has_moves(_/_/P2):-
	P2=..[pits,_|P2PitsList],
	(are_all_pits_zeros(P2PitsList),!,fail;true).

turn_over:-
	pos(T/P1/P2),!,
	next_player(T,N),
	set_pos(N/P1/P2).


are_all_pits_zeros([_]):-!.
are_all_pits_zeros([0|Pits]):-
	are_all_pits_zeros(Pits).

	
winner(Player):-
	pos(Pos),
	h(Pos, Val),
	winner(Val,Player).

winner(Val,player2):-
	Val > 0,!.
winner(Val,player1):-
	Val < 0,!.
winner(_,tie).
	
	

ad(B):-
repeat,
	in_range(A,1-3),
	(A=1,!,
		B=11
	;
		B=A
	),fail.


ab(B):-
	in_range(A,1-3),
	ac(A,B).

ac(1,11):-!.
ac(A,A).


