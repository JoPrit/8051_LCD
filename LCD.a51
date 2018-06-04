;------------------------------------------------------------------------------
$NOMOD51	; disable predefined 8051 registers
$INCLUDE (REG517A.INC)

; Vorgabedatei	

;Funktion:	LCD-Ausgabe


; Laborgruppe:B9


; Namen:Jannik Parma, Fabian Hartmann
;------------------------------------------------------------------------------
;=========================================
; Adressen
;=========================================
		RS		BIT P5.7
		RW		BIT	P5.6
		E		BIT	P5.5
		LCDBSY	BIT	P4.7
; ========================================
; Segmentdeklarationen
; ========================================
stack		SEGMENT	IDATA
Programm	SEGMENT	CODE

RSEG	stack
		DS	2
		
		CSEG	AT	0		; Sprung zum
		LJMP	main		; Hauptprogramm (Resetvektor)

RSEG	Programm

			USING	0  
main:	
		mov	SP,#stack-1

; ==============================================================================
; Initialisierungen
; ==============================================================================

;----- LCD initialisieren ----------
		call	lcd_init
;----- Text "Temperatur:" ausgeben -----
		mov	r5, #0		 ; LCD-Position für "Temperatur:"
		call 	LCD_Pos		 ; Cursor an diese Stelle
		mov dptr, #text1	 ; siehe Deklaration unten (Feste Programmdaten)
		call	LCD_Festtext
;----- Text "?C" ausgeben -----
		mov	r5, #4Eh		 ; LCD-Position für °C
		call 	LCD_Pos
		mov dptr, #text2
		call	LCD_Festtext

; ==============================================================================
; Hauptschleife 
; ==============================================================================
loop:
	jmp	loop
; Ende der Hauptschleife
; ------------------------------------------------------------------------------

; ==============================================================================
; Feste Programmdaten
; ==============================================================================
text1:	db	 'Temperatur:','$'							
text2:	db	 0xDF,'C','$'
;============================================================================
; Alle Unterprogramme:

; ===================
; LCD-Initialisierung
; ===================
lcd_init:
		mov R7, #70d	//mindestens 15ms lang warten = 60. wir warten 70 * 250µs
		call delay
		//(1) Function set: 8bit Interface
		clr RS
		clr RW
		mov P4, #30h	   //
		setb E
		clr E
		mov R7, #20	 //mindestens 4,1ms watten. wir warten 8ms
		call delay
		//(2) Function set
		setb E
		clr E
		mov R7, #1	 //mindestens 100µs wrten. wir warten 250µs
		call delay
		//(3) Function set
		setb E
		clr E
		//1.tes mal busy flag abfragen
		call busy
		//(4) Function set
		clr RS
		clr RW
		mov P4, #38h
		setb E
		clr E
		//2tes mal busy flag abfragen
		call busy
		//(5) Display Off
		clr RS
		clr RW
		mov P4, #08h
		setb E
		clr E
		//3tes mal busy flag abfragen
		call busy
		//(6) Display clear
		clr RS
		clr RW
		mov P4, #01h
		setb E
		clr E
		//4tes mal busy flag abfragen
		call busy
		//(7) Function set
		clr RS
		clr RW
		mov P4, #02h
		setb E
		clr E
		//Ende Init
		ret
		
; ===================
; 	DELAY
; ===================
;   Übergabeparameter R7 enthält Zahlenwert prportional zur Delayzeit
;   Forderung: Bei einem Übergabewert R7 := 1 soll
;   die Verzögerung wenig über 100 us	betragen
delay:
m2:		mov R5, #0FAh	//R5 bestimmt kleine schleife
m1:		djnz R5, m1		//Wird so lange runter gezählt bis 0
		djnz R7, m2		//Dann bestimmt R7 wie oft wir die R5 schleife wiederholen
		ret				//Eine R5 Schleife ist 250µs lang
; ***************************************
; LCD Busy Flag
; ***************************************
; Beim Simulationstest des Programms muss diese Funktion nach dem Einsprung
; sofort wieder mit ret verlassen werden! (Warum?) Weil wir kein LCD Display haben, das antworten könnte	
busy:
		ret			//auskommentieren für richtiges LCD!!!!
		clr RS
		mov P4, #80h //bit 7=1!!
		setb RW
		setb E
warte:	jb LCDBSY, warte //LCDBSY = P4.7
		clr E
		ret

; ====================
; Cursor positionieren
; ====================
; Übergabeparameter: R5 enthält DDRAM-AdressSet-Wert
LCD_Pos:
		clr RS		//RS = 0
		clr RW		//RW = 0
		mov P4, R5	//Den Wert, also die Cursor position, am port anlegen
		setb P4.7	//7tes bit von P4 auf 1 setzen (siehe DD RAM ADdress set in Anhang 4)
		setb E
		clr E
		ret

; ============================================
; 	Standardtext aus Tabelle auf LCD schreiben
; ============================================
; 	Übergabeparameter: dptr enthält Textadresse

LCD_Festtext:
Ausgabeschleife:
		mov a, 0					//a mit 0 vorladen, damit wir mit dem anfangen, auf das dptr zeigt
		movc a, @a+dptr				//ASCII zeichen von der stelle, auf die dptr zeigt in a laden
		cjne a, #'$', nichtzuende	//Pruefen, ob das Zeichen '$' ist, welches als ENDE-zeichen benutzt wird
		ret							//Wenn ja, dann raus aus dem Unterprogramm
nichtzuende:
		call busy					//busy flag abfragen, bevor der ausgang gesetzt wird
		setb RS						//RS und RW vorbereiten
		clr RW
		mov P4, a					//Wenn nein, dann das Zeichen auf den Bus legen
		setb E						//Und uebergeben
		clr E
		inc dptr					//Und ein Byte weiter springen
		jmp Ausgabeschleife
		ret

;====================================================================
; ---------------------------------------
		END			

