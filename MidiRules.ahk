; Last edited 12/18/2018 3:03 PM by genmce
;*************************************************
;*          RULES - MIDI FILTERS - 
;       MIDI INPUT TO KEY PRESS
;*************************************************
/* 
This section will deal with transforming midi; NoteOns, NoteOffs, Continuous Controllers and Program Change messages
You can 
- Transform the midi input > computer keypress(s) like a macro.  
- Transform the midi input > to some other type of midi output.
Both are possible in the same script.
This script does NOT, currently, pass the original midi messsage out.

There are a few ways to handle transformations
1. Set up a filter to detect correct type and data1 val - then run commands or 
2. Set up filter after type filter (NoteOn, NoteOff, CC or PC) under that section below -      
(Keep rules together under proper section, notes, cc, program change etc.
Keep them after the statusbyte has been determined.
Examples for each type of rule will be shown. 
The example below is for note type message.)

Statusbyte between 128 and 159 ; see range of values for notemsg var defined in autoexec section. "in" used because ranges of note on and note off
{ ; beginning of note block

statusbyte between 128 and 143 ARE NOTE OFF'S
statusbyte between 144 and 159 ARE NOTE ON'S 
statusbyte between 176 and 191 ARE CONTINUOS CONTROLLERS
statusbyte between 192 and 208  ARE PROGRAM CHANGE for data1 values

Remember: 
NoteOn/Off data1 = note number, data2 = velocity of that note.
CC - data1 = cc #, data2 = cc value 
Program Change - data1 = pc #, data2 - ignored

ifequal, data1, 20 ; if the note number coming in is note # 20
{
  data1 := (do something in here) ; could be do something to the velocity(data2)
  gosub, SendNote ; send the note out.
}
*/
/* 
  WHAT DO YOU REALLY WANT TO DO?
  CONVERT MIDI TO KEYSTROKE?  Line 45 this file 
  MODIFY MIDI INPUT AND SEND IT BACK OUT?
*/

;*****************************************************************
;   Midi input is detected in Midi_In_Out_Lib  - 
;   it automatically runs the MidiRules label
;*****************************************************************

initGlobals:
; Used if no modifiers are available
macros := {}
macros9 := { 0x80: ["{Left}", 16],    0x81: ["{Right}", 16],        0x82: ["{Up}", 16],          0x83: ["{Down}", 16],               0x84: ["^c^l", 34], 0x85: ["^c^n", 17],           0x86: [],                    0x87: ["", 2] }
macros1 := { 0x00: ["Bool ", 34],     0x01: ["true ", 16],          0x02: ["false ", 16],        0x03: ["if then else ", 1],         0x04: [],           0x05: ["{U+22A5} ", 34],      0x06: ["exfalso ", 1],       0x07: [],                            0x08: ["", 16] }
macros2 := { 0x10: ["{U+2115} ", 34], 0x11: ["zero ", 16],          0x12: ["suc ", 16],          0x13: ["primrec ", 1],              0x14: [],           0x15: ["{U+22A4} ", 34],      0x16: ["tt ", 16],           0x17: [],                            0x18: []       }
macros3 := { 0x20: ["{U+00D7} ", 34], 0x21: [", ", 16],             0x22: ["proj{U+2081} ", 1],  0x23: ["proj{U+2082} ", 1],         0x24: [],           0x25: ["{Enter}", 16],        0x26: ["{Backspace}", 18],   0x27: [],                            0x28: []       }
macros4 := { 0x30: ["{U+228E} ", 34], 0x31: ["inj{U+2081} ", 16],   0x32: ["inj{U+2082} ", 16],  0x33: ["case ", 1],                 0x34: [],           0x35: ["(", 17],              0x36: ["{Backspace}) ", 17], 0x37: [],                            0x38: []       }
macros5 := { 0x40: ["{U+03BB} ", 49], 0x41: ["= ", 49],             0x42: [": ", 49],            0x43: [" ", 0],                     0x44: [],           0x45: ["{U+00AC} ", 2],       0x46: ["{U+2194} ", 18],     0x47: ["{U+2192} ", 48],             0x48: []       }
macros6 := { 0x50: [],                0x51: [],                     0x52: [],                    0x53: [],                           0x54: [],           0x55: [],                     0x56: [],                    0x57: [],                            0x58: []       }
macros7 := { 0x60: ["a ", 17],        0x61: ["b ", 17],             0x62: ["c ", 17],            0x63: ["_ ", 1],                    0x64: ["x ", 16],   0x65: ["y ", 16],             0x66: ["z ", 16],            0x67: ["{Left}{U+2081}{Right}", 17], 0x68: []       }
macros8 := { 0x70: ["t ", 16],        0x71: ["u ", 16],             0x72: ["v ", 16],            0x73: ["{Left}'{Right}", 1],        0x74: ["X ", 1],    0x75: ["Y ", 1],              0x76: ["Z ", 1],             0x77: ["{Left}{U+2082}{Right}", 17], 0x78: []       }

; Used when MOD1 is active
macros_mod1 := { 0x80: ["^{Left}", 16], 0x81: ["^{Right}", 16], 0x82: ["{PgUp}", 16], 0x83: ["{PgDn}", 16], 0x26: ["^{Backspace}", 18] }

Loop 9
{
    for key, val in macros%A_Index%
    {
        macros[key] := val
    }
}

for key, val in macros
{
    if (key >= 0x80) {
        statusbyte := 176
        data1 := key - 24
    } else {
        statusbyte := 144
        data1 := key
    }

    if val[2] {
        data2 := val[2]
    } else {
        data2 := 0
    }
    
    gosub, SendNote
}

; Initialize special keystates
IfCounter := 1 ; 1 = if, 2 = then, 3 = else
IfLights  := [1, 18, 18]
Mod1      := 1 ; 1 = released, 2 = pressed-not-held, 3 = pressed-held, 4 = next-only, 5 = stuck
ModLights := [16, 34, 34, 33, 18]

Return

MidiRules: ; This label is where midi input is modified or converted to  keypress.



;*****************************************************************
;     EXAMPLE OF MIDI TO KEYPRESS - 
;*****************************************************************
;if  (stb = "NoteOn" And data1  = "36")  ; Example - if  msg is midi noteOn AND note# 36 - trigger msg box - could trigger keycommands  
;{
    ; MsgBox, 0, , Note %data1%, 1          ; show the msgbox with the note# for 1 sec

    ; msgbox,,,midirules %CC_num%,1

    ; UNCOMMENT LINE BELOW TO SEND A KEYPRESS WHEN NOTE 36 IS RECEIVED
    ; send , {NumLock} ; send a keypress when note number 20 is received.
;}

;*****************************************************************
; Compare statusbyte of recieved midi msg to determine type of 
; You could write your methods under which ever type of  midi you want to convert

; RETHINK HOW THESE ARE ORGANIZED AND MAYBE TO IT BY LINE
;*****************************************************************

if statusbyte between 144 and 159 ; detect if note message is "note on" 
{
    ;*****************************************************************
    ;    PUT ALL "NOTE ON" TRANSFORMATIONS HERE
    ;*****************************************************************

    ; Launchpad note-off event
    if (data2 == 0) {
        if (data1 == 0x03) { ; if-then-else
            data2 := IfLights[IfCounter]
        } else if (data1 == 0x08) { ; MOD1
            if (Mod1 == 3) { ; releasing held state
                Mod1 := 1
            } else if (Mod1 == 2) { ; single-press, next is mod'd
                Mod1 := 4
            }

            data2 := ModLights[Mod1]
        } else if (Mod1 != 1) and macros_mod1[data1] {
            data2 := macros_mod1[data1][2]
        } else if (macros[data1]) {
            data2 := macros[data1][2]
        } else {
            data2 := 0
        }
    } else if (data2 == 127) { ; Launchpad note-on event
        if (data1 == 0x08) { ; Handle Mod1 state changes
            if (Mod1 == 1) { ; "mod1 shift"
                Mod1 := 2
            } else if (Mod1 == 4) { ; "mod1 lock" on
                Mod1 := 5
            } else if (Mod1 == 5) { ; "mod1 lock" off
                Mod1 := 1
            }

            data2 := ModLights[Mod1]
        } else {
            if (data1 == 0x03) { ; if-then-else
                if (IfCounter == 1) {
                    Send, if{Space}
                } else if (IfCounter == 2) {
                    Send, then{Space}
                } else if (IfCounter == 3) {
                    Send, else{Space}
                    IfCounter := 0
                }

                IfCounter := IfCounter + 1
            } else if (Mod1 != 1) and macros_mod1[data1] {
                out := macros_mod1[data1][1]
                Send, %out%
            } else if (macros[data1]) {
                out := macros[data1][1]
                Send, %out%
            }

            ; handle mod1 changes
            if (Mod1 == 2) { ; shift is held under keys, instead of only the next one
                Mod1 := 3

                ; change mod lights
                bak1 := data1
                bak2 := data2
                data1 := 0x08
                data2 := ModLights[Mod1]
                gosub, SendNote

                ; restore backups
                data1 := bak1
                data2 := bak2
            } else if (Mod1 == 4) { ; reset on next-only
                Mod1 := 1

                ; change mod lights
                bak1 := data1
                bak2 := data2
                data1 := 0x08
                data2 := ModLights[Mod1]
                gosub, SendNote

                ; restore backups
                data1 := bak1
                data2 := bak2
            }

            ; static "key-pressed" light
            data2 := 51
        }
    }

    gosub, RelayNote ; send the note out.
}
   
; =============== END OF NOTE ON MESSAGES ; ===============
      
if statusbyte between 128 and 143 ; detect if note message is "note off"
{
    ;*****************************************************************
    ;   PUT ALL NOTE OFF TRANSFORMATIONS HERE
    ;*****************************************************************
    
    ; gosub, ShowMidiInMessage
    ; GuiControl,12:, MidiMsOut, noteOff:%statusbyte% %chan% %data1% %data2%  ; display note off in gui
}

/* 
Write your own note filters and put them in this section.
Remember data1 for a noteon/off is the note number, data2 is the velocity of that note.
example
ifequal, data1, 20 ; if the note number coming in is note # 20
{
    data1 := (do something in here) ; could be do something to the velocity(data2)
    gosub, SendNote ; send the note out.
}
*/
     
/*
;*****************************************************************
; ANOTHER MIDI TO KEYPRESS EXAMPLE
;*****************************************************************

ifequal, data1, 30 ; if the note number coming in is note # 30
{
    send , {NumLock} ; send a keypress when note number 20 is received.
}

; a little more complex filter two notes
if ((data1 != 60) and (data1 != 62)) ; if note message is not(!) 60 and not(!) 62 send the note out - ie - do nothing except statements above (note 20 and 30 have things to do) to it.
{
    gosub, SendNote ; send it out the selected output midi port
    ;msgbox, ,straight note, note %data1% message, 1 ; this messagebox for testing only.
}

IfEqual, data1, 60 ; if the note number is middle C (60) (you can change this)  
{
    data1 := (data1 + 5) ;transpost up 5 steps
    gosub, SendNote ;(h_midiout, note) ;send a note transposed up 5 notes.
    ;msgbox, ,transpose up 5, note on %data1% message, 1 ; for testing only - show msgbox for 1 sec
}

IfEqual, data1, 62 ; if note on is note number 62 (just another example of note detection)
{
    data1 := (data1 -5) ;transpose down 5 steps
    gosub, SendNote
    ;msgbox, ,transpose down 5, note on %data1% message, 1 ; for testing only, uncomment if you need it.
}	
*/

;*****************************************************************
;   IS INCOMING MSG IS A CC?
;*****************************************************************

if statusbyte between 176 and 191 ; check status byte for cc 176-191 is the range for CC messages
{
    ;*****************************************************************
    ;   PUT ALL CC TRANSFORMATIONS HERE 
    ;***************************************************************** 

    if (data1 == 111) { ; exit the app
        statusbyte := 176
        data1 := 0
        data2 := 0
        gosub, SendNote
        ExitApp
    } else { ; same as normal keys, except offset
        data1 := data1 + 24
        
        if (data2 == 0) { ; Launchpad note-off event
            if (Mod1 != 1) and macros_mod1[data1] {
                data2 := macros_mod1[data1][2]
            } else if (macros[data1]) {
                data2 := macros[data1][2]
            } else {
                data2 := 0
            }
        } else if (data2 == 127) { ; Launchpad note-on event
            if (Mod1 != 1) and macros_mod1[data1] {
                out := macros_mod1[data1][1]
                Send, %out%
            } else if (macros[data1]) {
                out := macros[data1][1]
                Send, %out%
            }

            ; handle mod1 changes
            if (Mod1 == 2) { ; shift is held under keys, instead of only the next one
                Mod1 := 3

                ; change mod lights
                bak1 := data1
                bak2 := data2
                data1 := 0x08
                data2 := ModLights[Mod1]
                gosub, SendNote

                ; restore backups
                data1 := bak1
                data2 := bak2
            } else if (Mod1 == 4) { ; reset on next-only
                Mod1 := 1

                ; change mod lights
                bak1 := data1
                bak2 := data2
                data1 := 0x08
                data2 := ModLights[Mod1]
                gosub, SendNote

                ; restore backups
                data1 := bak1
                data2 := bak2
            }

            ; static "key-pressed" light
            data2 := 51
        }

        data1 := data1 - 24 ; reset offset for relay
        gosub, RelayCC ; relay message unchanged 
    }
}
  
;*****************************************************************
; IS INCOMING MSG A PROGRAM CHANGE MESSAGE?
;*****************************************************************
if statusbyte between 192 and 208  ; check if message is in range of program change messages for data1 values. ; !!!!!!!!!!!! no edit
{
    ;*****************************************************************
    ; PUT ALL PC TRANSFORMATIONS HERE
    ;*****************************************************************
    
    ; Sorry I have not created anything for here nor for pitchbends....

    gosub, sendPC

    ; need something for it to do here, could be converting to a cc or a note or changing the value of the pc
    ; however, at this point the only thing that happens is the gui change, not midi is output here.
    ; you may want to make a SendPc: label below
}

Return
