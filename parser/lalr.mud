<ZZPACKAGE "lalr">
; "This is not really ZIL code, even though it sort of pretends to be..."

<ENTRY LALR MAKE-TABLES BIG-Q
       PRINT-ACTION-TABLE PRINT-STATE>

<INCLUDE "basedefs" "lalrdefs" "symbols" "set">

<USE-WHEN <COMPILING? "lalr"> "sort-macros">

"ACTION-TABLE has length word, which saves a lot a grief..."
<DEFINE PRINT-ACTION-TABLE PAT ("OPTIONAL"
				(AT:TABLE ,ACTION-TABLE)
				(OUT:<OR STRING CHANNEL> .OUTCHAN)
				"AUX" (CSTATE:FIX 0) CH)
  <COND (<TYPE? .OUT CHANNEL>
	 <SET CH .OUT>)
	(T ;<TYPE? .OUT STRING>
	 <COND (<NOT <SET CH <OPEN "PRINT" .OUT>>>
		<RETURN .CH .PAT>)>)>
  <REPEAT ((N:FIX <ZGET .AT 0>))
    <COND (<G? <SET CSTATE <+ .CSTATE 1>> .N>
	   <RETURN>)>
    <PRINT-STATE <ZGET .AT .CSTATE> .CH .CSTATE>>
  <COND (<TYPE? .OUT STRING>
	 <CLOSE .CH>)>
  T>

<DEFINE PRINT-STATE (ST:<OR FIX TABLE> "OPT" (OUTCHAN:CHANNEL .OUTCHAN)
		       (SID:FIX 1))
  <COND (<TYPE? .ST FIX>
	 <SET SID .ST>
	 <SET ST <ZGET ,ACTION-TABLE .ST>>)>
  <PRINT-MANY .OUTCHAN PRINC PRMANY-CRLF "State # " .SID ":" PRMANY-CRLF>
  <PRINT-TERMINAL-STATE <ZGET .ST 0> <1 ,SYMBOL-VECTOR> .OUTCHAN>
  <PRINT-NONTERMINAL-STATE <ZGET .ST 1> <2 ,SYMBOL-VECTOR> .OUTCHAN>>

<DEFINE PRINT-NONTERMINAL-STATE (VV:<OR TABLE FALSE> SV:VECTOR OUTCHAN:CHANNEL)
  <COND
   (.VV
    <REPEAT (IT)
      <COND (<0? <GETB .VV 0>:FIX> <RETURN>)>
      <PRINT-MANY .OUTCHAN PRINC <SYM-NAME <NTH .SV <GETB .VV 0>>> ":	">
      <SET IT <M-HPOS .OUTCHAN>>
      <PRINT-FROB <GETB .VV 1> .OUTCHAN .IT>
      <SET VV <ZREST .VV 2>>>)>>

<DEFINE PRINT-BIT-WORDS (WD-ONE:FIX WD-TWO:FIX SV:VECTOR OUTCHAN:CHANNEL
			   "AUX" (NOCOMMA? T) ;TOK STR
			   (WDS <TUPLE .WD-ONE .WD-TWO>))
  <MAPF <>
    <FUNCTION (WD:FIX MSK:FIX)
      <REPEAT ((CT 0) (BIT 1))
        <COND (<NOT <0? <ANDB .WD .BIT>>>
	       <COND (<G? <+ <M-HPOS .OUTCHAN>:FIX
			     <LENGTH
			      <SET STR
				   <SPNAME <GET-TYPE <ORB .BIT .MSK>>>>>>
			  25>
		      <PRINT-MANY .OUTCHAN PRINC "," PRMANY-CRLF>
		      <SET NOCOMMA? T>)>
	       <PRINT-MANY .OUTCHAN PRINC <COND (.NOCOMMA? "")(", ")>
			   .STR>
	       <SET NOCOMMA? <>>)>
	<COND (<G=? <SET CT <+ .CT 1>> 15>
	       <RETURN>)>
	<SET BIT <LSH .BIT 1>>>>
    .WDS '[*100000* 0]>>

<DEFINE PRINT-TERMINAL-STATE (L:TABLE ;<VECTOR [REST FIX FIX <OR FIX LIST>]>
			        SV:VECTOR OUTCHAN:CHANNEL
			        "AUX" (SHORT? <L=? ,NUMBER-WORD-CLASSES 15>))
  <REPEAT (IT FROB)
    <COND (<AND <0? <ZGET .L 0>:FIX>
		<OR .SHORT?
		    <0? <ZGET .L 1>:FIX>>>
	   <RETURN>)>
    <COND (.SHORT?
	   <PRINT-BIT-WORDS 0 <ZGET .L 0> .SV .OUTCHAN>)
	  (T
	   <PRINT-BIT-WORDS <ZGET .L 0> <ZGET .L 1> .SV .OUTCHAN>)>
    <PRINC ":  ">
    <SET IT <M-HPOS .OUTCHAN>>
    <SET FROB <COND (.SHORT? <ZGET .L 1>)
		    (T <ZGET .L 2>)>>
    <COND (<TYPE? .FROB TABLE>
	   <REPEAT ((LEN:FIX <GETB .FROB 0>) (CT:FIX 1))
	     <PRINT-FROB <GETB .FROB .CT> .OUTCHAN .IT>
	     <COND (<G? <SET CT <+ .CT 1>> .LEN> <RETURN>)>>)
	  (T
	   <PRINT-FROB .FROB .OUTCHAN .IT>)>
    <SET L <ZREST .L <COND (.SHORT? 4) (T 6)>>>>>

<DEFINE PRINT-FROB (FROB:FIX OUTCHAN:CHANNEL IT:FIX "AUX" RED:REDUCTION
		      RF)
  <INDENT-TO .IT .OUTCHAN>
  <COND (<==? .FROB ,ACTION-SPLIT>
	 <PRINC "DONE
">)
	(<L? .FROB ,ACTION-SPLIT>
	 <PRINT-MANY .OUTCHAN PRINC "-->State " .FROB PRMANY-CRLF>)
	(T
	 <SET RED <ZGET ,REDUCTION-TABLE <- .FROB ,REDUCTION-OFFSET>>>
	 <PRINT-MANY .OUTCHAN PRINC "Apply "
		     <COND (<TYPE? <SET RF <REDUCTION-FUNCTION .RED>> ATOM>
			    .RF)
			   (<TYPE? .RF MSUBR>
			    <2 .RF>)
			   (T "function")>
		      " to " <REDUCTION-SIZE .RED> ", new token is "
		      <SYM-NAME <NTH <2 ,SYMBOL-VECTOR>
				     <REDUCTION-RESULT .RED>>>
		      PRMANY-CRLF>)>>

<DEFINE LALR ("OPT" (LR1 <>))
  <SETG NUM-OF-STATES 0>
  <COMPUTE-FIRSTS>
  <BIND ((BIG-Q:SET <MAKE-SET>)
	 (FIRST-STATE:STATE <MAKE-STATE <MAKE-SET>>))
    <MAPF <>
	  <FUNCTION (PROD:PRODUCTION)
	    <ADD-OBJ-TO-SET
	     <MAKE-ITEM .PROD 0 <MAKE-SET ,END-OF-INPUT-SYMBOL>>
	     <STATE-SET .FIRST-STATE>>>
	  <SYM-PRODS ,START-SYMBOL>:<LIST [REST PRODUCTION]>>
    <CLOSURE <STATE-SET .FIRST-STATE> .LR1>
    <ADD-OBJ-TO-SET .FIRST-STATE .BIG-Q>
    <REPEAT (Q:<OR FALSE STATE> BASIS:SET Q-PRIME:<OR FALSE STATE>)
      <SET Q
	   <MAPSET <>
		   <FUNCTION (AQ:STATE)
		     <COND (<NOT <STATE-CONSIDERED? .AQ>>
			    <STATE-CONSIDERED? .AQ T>
			    <MAPLEAVE .AQ>)>>
		   .BIG-Q>>
      <COND (<NOT .Q> <RETURN>)>
      <MAPF <>
	    <FUNCTION (SYM:SYMBOL)
	      <SET BASIS <MAKE-BASIS <STATE-SET .Q> .SYM>>
	      <COND (<NOT <IS-EMPTY-SET? .BASIS>>
		     <SET Q-PRIME
			  <MAPSET <>
				  <FUNCTION (QP:STATE)
				    <AND <KERNELS-ARE-EQUAL?
					  .BASIS <STATE-SET .QP>>
					 <MAPLEAVE .QP>>>
				  .BIG-Q>>
		     <COND (.Q-PRIME
			    <COND (<MERGE-SET-WITH-SET
				    .BASIS <STATE-SET .Q-PRIME> .LR1>
				   ; "PER SAM, 3/9/87; OTHERWISE, MAY MISS
				      SOME PARSES"
				   <CLOSURE <STATE-SET .Q-PRIME> .LR1>
				   <STATE-CONSIDERED? .Q-PRIME <>>)>)
			   (ELSE
			    <CLOSURE .BASIS .LR1>
			    <ADD-OBJ-TO-SET <MAKE-STATE .BASIS> .BIG-Q>)>)>>
	    ,ALL-SYMBOLS>>
    .BIG-Q>>


<DEFINE CLOSURE (SET:SET LR1:<OR ATOM FALSE>)
  <MAPSET <>
	  <FUNCTION (ITEM:ITEM) <ITEM-CLOSED? .ITEM <>>>
	  .SET>
  <REPEAT (ITEM:<OR FALSE ITEM> SYM:SYMBOL PROD:PRODUCTION FOLLOWS:SET)
    <SET ITEM
	 <MAPSET <>
		 <FUNCTION (I:ITEM)
		   <COND (<NOT <ITEM-CLOSED? .I>>
			  <ITEM-CLOSED? .I T>
			  <MAPLEAVE .I>)>>
		 .SET>>
    <COND (<NOT .ITEM> <RETURN>)>
    <SET PROD <ITEM-PROD .ITEM>>
    <COND (<L? <ITEM-DOT .ITEM> <PROD-LENGTH .PROD>>
	   <SET FOLLOWS <MAKE-SET ,EPSILON-SYMBOL>>
	   <MAPF <>
		 <FUNCTION (R:SYMBOL "AUX" (F <SYM-FIRSTS .R>))
		   <ADD-SET-TO-SET .F .FOLLOWS>
		   <COND (<NOT <IN-SET? ,EPSILON-SYMBOL .F>>
			  <REMOVE-OBJ-FROM-SET ,EPSILON-SYMBOL .FOLLOWS>
			  <MAPLEAVE>)>>
		 <REST <PROD-RIGHT .PROD> <+ <ITEM-DOT .ITEM> 1>>>
	   <COND (<IN-SET? ,EPSILON-SYMBOL .FOLLOWS>
		  <REMOVE-OBJ-FROM-SET ,EPSILON-SYMBOL .FOLLOWS>
		  <ADD-SET-TO-SET <ITEM-FOLLOWS .ITEM> .FOLLOWS>)>
	   <COND (<MEMQ <SET SYM
			     <NTH <PROD-RIGHT .PROD>
				  <+ <ITEM-DOT .ITEM> 1>>>
			,ALL-NONTERMINALS>
		  <MAPF <>
			<FUNCTION (P:PRODUCTION)
			  <MERGE-ITEM-WITH-SET
			   <MAKE-ITEM .P 0 <COPY-SET .FOLLOWS>>
			   .SET .LR1>>
			<SYM-PRODS .SYM>:<LIST [REST PRODUCTION]>>)>)>>>

<DEFINE MERGE-ITEM-WITH-SET TOP (ITEM:ITEM SET:SET LR1)
  <MAPSET <>
	  <FUNCTION (SET-ITEM:ITEM)
	    <COND (<AND <==? <ITEM-PROD .ITEM> <ITEM-PROD .SET-ITEM>>
			<==? <ITEM-DOT .ITEM> <ITEM-DOT .SET-ITEM>>
			<OR <NOT .LR1>
			    <SET=? <ITEM-FOLLOWS .ITEM>
				   <ITEM-FOLLOWS .SET-ITEM>>>>
		   <COND (<ADD-SET-TO-SET <ITEM-FOLLOWS .ITEM>
					  <ITEM-FOLLOWS .SET-ITEM>>
			  <ITEM-CLOSED? .SET-ITEM <>>
			  <RETURN T .TOP>)
			 (ELSE <RETURN <> .TOP>)>)>>
	  .SET>
  <ADD-OBJ-TO-SET .ITEM .SET>>

<DEFINE SET=? SE (SET1:SET SET2:SET)
  <MAPSET <>
    <FUNCTION (EL1:ANY "AUX" (WINNER? T))
      <COND (<NOT <MEMQ .EL1 <SET-ELEMENTS .SET2>>>
	     <RETURN <> .SE>)>>
    .SET1>
  T>

<DEFINE KERNELS-ARE-EQUAL? TOP (A:SET B:SET)
  <MAPSET <>
	  <FUNCTION (A-ITEM:ITEM)
	    <OR <0? <ITEM-DOT .A-ITEM>>
		<MAPSET <>
			<FUNCTION (B-ITEM:ITEM)
			  <AND <==? <ITEM-PROD .A-ITEM> <ITEM-PROD .B-ITEM>>
			       <==? <ITEM-DOT .A-ITEM> <ITEM-DOT .B-ITEM>>
			       <MAPLEAVE T>>>
			.B>
		<RETURN <> .TOP>>>
	  .A>
  <MAPSET <>
	  <FUNCTION (B-ITEM:ITEM)
	    <OR <0? <ITEM-DOT .B-ITEM>>
		<MAPSET <>
			<FUNCTION (A-ITEM:ITEM)
			  <AND <==? <ITEM-PROD .B-ITEM> <ITEM-PROD .A-ITEM>>
			       <==? <ITEM-DOT .B-ITEM> <ITEM-DOT .A-ITEM>>
			       <MAPLEAVE T>>>
			.A>
		<RETURN <> .TOP>>>
	  .B>
  T>

<DEFINE MERGE-SET-WITH-SET (FROM:SET TO:SET LR1)
  <BIND ((CHANGE <>))
    <MAPSET <>
	    <FUNCTION (F:ITEM)
	      <COND (<MERGE-ITEM-WITH-SET .F .TO .LR1>
		     <SET CHANGE T>)>>
	    .FROM>
    .CHANGE>>

<DEFINE MAKE-BASIS (Q:SET SYM:SYMBOL)
  <BIND ((BASIS:SET <MAKE-SET>))
    <MAPSET <>
	    <FUNCTION (ITEM:ITEM "AUX" (PROD <ITEM-PROD .ITEM>))
	      <COND (<AND <L? <ITEM-DOT .ITEM> <PROD-LENGTH .PROD>>
			  <==? <NTH <PROD-RIGHT .PROD> <+ <ITEM-DOT .ITEM> 1>>
			       .SYM>>
		     <ADD-OBJ-TO-SET
		      <MAKE-ITEM .PROD
				 <+ <ITEM-DOT .ITEM> 1>
				 <COPY-SET <ITEM-FOLLOWS .ITEM>>>
		      .BASIS>)>>
	    .Q>
    .BASIS>>

<DEFMAC STATE-L=? ('A 'B)
  <FORM L=? <FORM STATE-NUMBER .A> <FORM STATE-NUMBER .B>>>

<DEFINE MERGESORT-STATES (L:<LIST [REST STATE]> LEN:FIX)
  <MERGESORT-MACRO MERGESORT-STATES .L .LEN STATE-L=?>>

<DEFINE SORT-STATES (BIG-Q:SET)
  <1 .BIG-Q <MERGESORT-STATES <1 .BIG-Q> <LENGTH <1 .BIG-Q>>>>>

<DEFMAC PROD-L=? ('A 'B)
  <FORM L=? <FORM PROD-NUMBER .A> <FORM PROD-NUMBER .B>>>

<DEFINE SORT-PRODUCTIONS (L:<LIST [REST PRODUCTION]> LEN:FIX)
  <MERGESORT-MACRO SORT-PRODUCTIONS .L .LEN PROD-L=?>>

<DEFMAC SYM-L=? ('A 'B)
  <FORM BIND ((SNA <FORM SYM-NUMBER .A>) (SNB <FORM SYM-NUMBER .B>))
    '<COND (<L? .SNA 0>
	    <COND (<L? .SNB 0>
		   <G=? .SNA .SNB>)
		  (T <>)>)
	   (<L? .SNB 0> T)
	   (T
	    <L=? .SNA .SNB>)>>>

<DEFINE SORT-SYMBOLS (L:<LIST [REST SYMBOL]> LEN:FIX)
  <MERGESORT-MACRO SORT-SYMBOLS .L .LEN SYM-L=?>>

<DEFINE ADD-RES (ACTION RES)
  <COND (<TYPE? .RES FALSE> .ACTION)
	(<TYPE? .RES FIX> (.ACTION .RES))
	(<TYPE? .RES LIST>
	 ; "Build in reverse order, because the second case seems to
	    work more often than the first"
	 <PUTREST <REST .RES <- <LENGTH .RES> 1>> (.ACTION)>
	 .RES)
	(ELSE <ERROR BAD-RESULT-TYPE!-ERRORS <TYPE .RES> ADD-RES>)>>

<DEFINE MAKE-TABLES (BIG-Q:SET "AUX" (FIRST? T) (FIRST-RED? T))
  ;"Sort BIG-Q before we begin so that OUR tables will come out sorted, too"
  <SORT-STATES .BIG-Q>
  <SETG BIG-Q .BIG-Q>
  <SETG ALL-SYMBOLS <SORT-SYMBOLS ,ALL-SYMBOLS <LENGTH ,ALL-SYMBOLS>>>
  <SETG ALL-TERMINALS <SORT-SYMBOLS ,ALL-TERMINALS <LENGTH ,ALL-TERMINALS>>>
  <SETG ALL-NONTERMINALS
	<SORT-SYMBOLS ,ALL-NONTERMINALS <LENGTH ,ALL-NONTERMINALS>>>
  ;"Generate the parser tables"
  ;"Sort the productions so that our reduction table will come out sorted."
  <SETG ALL-PRODUCTIONS
	<SORT-PRODUCTIONS ,ALL-PRODUCTIONS <LENGTH ,ALL-PRODUCTIONS>>>
  <CONSTANT REDUCTION-TABLE
   <SETG REDUCTION-TABLE
	<MAPF ,TABLE
	      <FUNCTION (P:PRODUCTION "AUX" RED)
		<COND (<COMPILATION-FLAG-VALUE "P-DEBUGGING-PARSER">
		       <SET RED
		        <MAKE-REDUCTION 'REDUCTION-RESULT
					<- <SYM-NUMBER <PROD-LEFT .P>>>
					'REDUCTION-SIZE <PROD-LENGTH .P>
					'REDUCTION-FUNCTION <PROD-FCN .P>
					'REDUCTION-ERR-PRIORITY
					<PROD-ERR-PRIORITY .P>
					'REDUCTION-PRIORITY <PROD-PRIORITY .P>
					'REDUCTION-NAME
					<SPNAME <PROD-FCN .P>>>>)
		      (T
		       <SET RED
			    <TABLE (PARSER-TABLE)
				   <PROD-LENGTH .P>
				   <PROD-FCN .P>
				   <PROD-ERR-PRIORITY .P>
				   <PROD-PRIORITY .P>
				   <- <SYM-NUMBER <PROD-LEFT .P>>>>>)>
		<COND (.FIRST-RED?
		       <SET FIRST-RED? <>>
		       <MAPRET (PARSER-TABLE) .RED>)
		      (T
		       .RED)>>
	      ,ALL-PRODUCTIONS>>>
  <CONSTANT ACTION-TABLE
   <SETG ACTION-TABLE
	<MAPSET
	 ,TABLE
	 <FUNCTION (Q:STATE "AUX" VAL)
	   <SET VAL
		<TABLE (PARSER-TABLE)
		 <MAKE-TERMINAL-STATE .Q .BIG-Q ,ALL-TERMINALS>
		 <MAKE-NONTERMINAL-STATE .Q .BIG-Q ,ALL-NONTERMINALS>>>
	   <COND (.FIRST?
		  <SET FIRST? <>>
		  ; "Give it a length word along with everything else..."
		  <MAPRET (PARSER-TABLE LENGTH)
			  .VAL>)
		 (T
		  .VAL)>>
	 .BIG-Q>>>
  T>

<DEFINE MAKE-TERMINAL-STATE (Q:STATE BIG-Q:SET L:<LIST [REST SYMBOL]>
			     "AUX" (TE:<PRIMTYPE LIST> <>))
  <MAPF <>
    <FUNCTION (SYM:SYMBOL "AUX" NEXT (RES:<OR FIX FALSE LIST> <>) NRES)
      <COND (<N==? .SYM ,EPSILON-SYMBOL>
	     <COND (<SET NEXT <FIND-NEXT-STATE .Q .SYM .BIG-Q>>
		    <SET RES <ADD-RES <STATE-NUMBER .NEXT> .RES>>)>
	     <MAPSET <>
	       <FUNCTION (ITEM:ITEM "AUX" (PROD <ITEM-PROD .ITEM>))
	         <COND (<AND <==? <ITEM-DOT .ITEM>
				  <PROD-LENGTH .PROD>>
			     <IN-SET? .SYM <ITEM-FOLLOWS .ITEM>>>
			<COND (<==? <PROD-LEFT .PROD> ,START-SYMBOL>
			       <SET RES <ADD-RES ,ACTION-SPLIT .RES>>)
			      (T
			       <SET RES
				    <ADD-RES <+ <PROD-NUMBER .PROD>
						,REDUCTION-OFFSET
						-1>
					     .RES>>)>)>>
	       <STATE-SET .Q>>)>
      <COND (.RES
	     <COND (<TYPE? .RES LIST>
		    ; "Canonicalize the list"
		    <SET NRES <TABLE (LENGTH BYTE PARSER-TABLE)
				      !<SORT-RES-LIST .RES <LENGTH .RES>>>>)
		   (T
		    <SET NRES .RES>)>
	     <REPEAT ((LL:<<PRIMTYPE LIST> [REST VECTOR]> .TE)
		      E:<VECTOR FIX FIX> SN)
	       <COND (<NOT <0? <ANDB <SET SN <SYM-NUMBER .SYM>> *100000*>>>
		      <SET SN <LSH <ANDB .SN *77777*> 15>>)>
	       <COND (<EMPTY? .LL>
		      <SET TE ([.SN
				<SYM-WEIGHT .SYM>
				.NRES] !.TE)>
		      <RETURN>)
		     (<=? <3 <SET E <1 .LL>>> .NRES>
		      <1 .E <ORB <1 .E> .SN>>
		      <2 .E <+ <2 .E> <SYM-WEIGHT .SYM>>>
		      <RETURN>)>
	       <SET LL <REST .LL>>>)>>
    .L>
  <COND (.TE <FINISH-TERMINAL-STATE .TE>)>>

<DEFINE FINISH-TERMINAL-STATE (TE:<LIST [REST VECTOR]>
			       "AUX" (SHORT? <L=? ,NUMBER-WORD-CLASSES 15>)
				     (FIRST? T))
  <SET TE <SORT-TERMINAL-STATE .TE <LENGTH .TE>>>
  <MAPR ,TABLE
    <FUNCTION (L:LIST "AUX" (X:VECTOR <1 .L>) (RR <3 .X>)
	       OTHER)
      <COND (.FIRST?
	     <SET FIRST? <>>
	     <SET OTHER ((PARSER-TABLE))>)
	    (T
	     <SET OTHER ()>)>
      <COND (<NOT <EMPTY? <REST .L>>>
	     <COND (.SHORT?
		    <MAPRET !.OTHER <1 .X> .RR>)
		   (T
		    <MAPRET !.OTHER
			    <LSH <1 .X> -15> <ANDB <1 .X> *77777*> .RR>)>)
	    (.SHORT?
	     <MAPRET !.OTHER <1 .X> .RR 0>)
	    (T
	     <MAPRET !.OTHER <LSH <1 .X> -15> <ANDB <1 .X> *77777*> .RR 0 0>)>>
    .TE>>

; "Sort so entries with the most bits on are first in the list."
<DEFINE SORT-TERMINAL-STATE (TE:LIST LEN:FIX)
  <MERGESORT-MACRO SORT-TERMINAL-STATE .TE .LEN TS-L=?>>

<DEFINE TS-L=? (ARG1:<VECTOR FIX FIX> ARG2:<VECTOR FIX FIX>)
  <G? <2 .ARG1> <2 .ARG2>>>

<DEFINE SORT-RES-LIST (RES:<LIST [REST FIX]> LEN:FIX)
  <MERGESORT-MACRO SORT-RES-LIST .RES:<LIST [REST FIX]> .LEN RES-L=?>>

<DEFINE RES-L=? (RES1:FIX RES2:FIX "AUX" RED1 RED2)
  <COND (<AND <G? .RES1 ,ACTION-SPLIT>
	      <G? .RES2 ,ACTION-SPLIT>>
	 ; "Both of these are reductions, so make the one with the most
	    tokens come first..."
	 <COND (<==? <REDUCTION-PRIORITY
		      <SET RED1 <ZGET ,REDUCTION-TABLE
				      <- .RES1 ,REDUCTION-OFFSET>>>>
		     <REDUCTION-PRIORITY
		      <SET RED2 <ZGET ,REDUCTION-TABLE
				      <- .RES2 ,REDUCTION-OFFSET>>>>>
		<G=? <REDUCTION-SIZE <ZGET ,REDUCTION-TABLE
					   <- .RES1 ,REDUCTION-OFFSET>>>
		     <REDUCTION-SIZE <ZGET ,REDUCTION-TABLE
					   <- .RES2 ,REDUCTION-OFFSET>>>>)
	       (T
		<G=? <REDUCTION-PRIORITY .RED1> <REDUCTION-PRIORITY .RED2>>)>)
	(T
	 <L=? .RES1 .RES2>)>>

<DEFINE MAKE-NONTERMINAL-STATE (Q:STATE BIG-Q:SET SYMLIST:<LIST [REST SYMBOL]>
			  "AUX" (SLIST <>))
  <MAPF <>
    <FUNCTION (SYM:SYMBOL "AUX" (RES <>) (NEXT:<OR FALSE STATE> <>))
      <COND (<==? .SYM ,EPSILON-SYMBOL>)
	    (T
	     <COND (<SET NEXT <FIND-NEXT-STATE .Q .SYM .BIG-Q>>
		    <SET RES <ADD-RES <STATE-NUMBER .NEXT> .RES>>)>
	     <MAPSET <>
	       <FUNCTION (ITEM:ITEM "AUX" (PROD <ITEM-PROD .ITEM>))
	         <COND (<AND <==? <ITEM-DOT .ITEM>
				  <PROD-LENGTH .PROD>>
			     <IN-SET? .SYM <ITEM-FOLLOWS .ITEM>>>
			<COND (<==? <PROD-LEFT .PROD> ,START-SYMBOL>
			       <SET RES <ADD-RES 0 .RES>>)
			      (ELSE
			       <SET RES
				    <ADD-RES <+ <PROD-NUMBER .PROD>
						,REDUCTION-OFFSET
						-1>
					     .RES>>)>)>>
	       <STATE-SET .Q>>
	     <COND (.RES
		    <COND (<TYPE? .RES LIST>
			   <ERROR AMBIGUITY-IN-NONTERMINAL-STATE!-ERRORS>
			   <SET RES <TABLE (LENGTH PARSER-TABLE BYTE) !.RES>>)>
		    <SET SLIST (<- <SYM-NUMBER .SYM>> .RES !.SLIST)>)>)>>
    .SYMLIST>
  <COND (<NOT <EMPTY? .SLIST>>
	 <TABLE (BYTE PARSER-TABLE) !.SLIST 0>)>>

<DEFINE FIND-NEXT-STATE (Q:STATE SYM:SYMBOL BIG-Q:SET)
  <BIND ((BASIS:SET <MAKE-BASIS <STATE-SET .Q> .SYM>))
    <COND (<NOT <IS-EMPTY-SET? .BASIS>>
	   <MAPSET <>
		   <FUNCTION (QP:STATE)
		     <AND <KERNELS-ARE-EQUAL? .BASIS <STATE-SET .QP>>
			  <MAPLEAVE .QP>>>
		   .BIG-Q>)>>>

<ENDPACKAGE>
