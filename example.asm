.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern scanf: proc
extern printf: proc

includelib canvas.lib
extern BeginDrawing: proc
extern puts: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
dg1	  db 'Ati introdus 1 digit',13,10,10,'$'
ora	  db  3,?,?,?,?
window_title DB "Proiect Sudoku",0
area_width EQU 900
area_height EQU 900
area DD 2
msg DB "n=", 0
mesaje db "i=%d j=%d" ,0
 n DD 0
 format DB "%d", 0
 margine_stanga_x dd 0
 margine_stanga_y dd 0
 margine_dreapta_x dd 0
 margine_dreapta_y dd 0
 i dd 0
 j dd 0
;vertical DB "dddd", 0

counter DD 0 ; numara evenimentele de tip timer
solutie dd 5,3,4,6,7,8,9,1,2
		dd 6,7,2,1,9,5,3,4,8
		dd 1,9,8,3,4,2,5,6,7
		dd 8,5,9,7,6,1,4,2,3
		dd 4,2,6,8,5,3,7,9,1
		dd 7,1,3,9,2,4,8,5,6
		dd 9,6,1,5,3,7,2,8,4
		dd 2,8,7,4,1,9,6,3,5
		dd 3,4,5,2,8,6,1,7,9
matrice_de_afisat dd 5,3,0,0,7,0,0,0,0
				  dd 6,0,0,1,9,5,0,0,0
				  dd 0,9,8,0,0,0,0,6,0
				  dd 8,0,0,0,6,0,0,0,3
				  dd 4,0,0,8,0,3,0,0,1
				  dd 7,0,0,0,2,0,0,0,6
				  dd 0,6,0,0,0,0,2,8,0
				  dd 0,0,0,4,1,9,0,0,5
				  dd 0,0,0,0,8,0,0,7,9
arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc

button_x EQU  150
button_y EQU  200
button_size EQU 450

mouseClick dw 0
mouseX dd 30
mouseY dd 30
mousePOs dw 0
tasta dd '1'

culoare_text DD 0h
.code
M_afisare_careu macro
	pusha
	mov ebx, 168
	mov eax, 220
	mov esi, 0
	mov ecx, 9
	loop_exterior :
		push ecx
		mov ecx,9
		loop_interior :
			add matrice_de_afisat[esi], '0'
			cmp matrice_de_afisat[esi], '0'
			je loc_liber
			jmp cifra_utilizata
			loc_liber :
				make_text_macro ' ', area, ebx, eax
				jmp after
			cifra_utilizata:
				make_text_macro matrice_de_afisat[esi], area, ebx, eax
			after :
				
			sub matrice_de_afisat[esi], '0'
			add esi, 4
			add ebx, 50
			loop loop_interior
		add eax, 50
		mov ebx,160
		pop ecx
		loop loop_exterior
		popa
endm
buton macro 
	local fail 
	pusha 
	mov eax,i
	mov ebx,j 
	cmp eax,685
	jl fail
	cmp eax,755
	jg fail
	cmp ebx,79
	jl fail
	cmp ebx,139
	jg fail
	mov tasta,'2'
	mov culoare_text, 0EED03Bh
	fail :
	
	popa
	
endm
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	cmp byte ptr [esi], 1
	je simbol_pixel_culoare
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
	jmp simbol_pixel_next
simbol_pixel_culoare:
	mov dword ptr [edi], 0
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

;citim de la tastatura
tast:
	push offset msg
	call printf
	add ESP, 4
	push offset n ;echivalent cu &n din C
	push offset format
	call scanf
	add ESP, 8
	
; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

line_horizontal macro x, y, len, color
local bucla_linie
	mov eax, y ;EAX=y
	mov ebx, area_width
	mul ebx ;EAX=y*area_width
	add eax,x 
	shl eax,2 ;pozitia in vectorul
	add eax, area
	mov ecx,len
bucla_linie :
	mov dword ptr[eax],color
	add eax, 4
	loop bucla_linie
endm

line_vertical macro x, y, len, color
local bucla_linie
	mov eax, y ;EAX=y
	mov ebx, area_width
	mul ebx ;EAX=y*area_width
	add eax,x 
	shl eax,2 ;pozitia in vectorul
	add eax, area
	mov ecx,len
bucla_linie :
	mov dword ptr[eax],color
	add eax, area_width*4
	loop bucla_linie
endm

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click, 3 - s-a apasat o tasta)
; arg2 - x (in cazul apasarii unei taste, x contine codul ascii al tastei care a fost apasata)
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	pusha
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax,2
	jz evt_timer
	
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	jmp afisare_litere
	
evt_click:
	buton
	push eax
	mov eax, [ebp+arg3]
	mov j, eax
	mov eax,[ebp+arg2]
	mov i, eax
	make_text_macro tasta, area, i, j 
	pop eax 
	make_text_macro '0', area, 23, 57
	; mov i,0
	; mov j,0
	; mov margine_stanga_x,150
	; mov margine_stanga_y, 200
	; mov margine_dreapta_x,600
	; mov margine_dreapta_y,200
	
	
	; verif_click_in_patrat_y :
		; mov eax, [ebp+arg3] ;coordonate y
		; cmp eax,200
		; jg verif_click_in_patrat_y_1
			; jmp continuare  
			  
			; verif_click_in_patrat_y_1: 
					; cmp eax,650
					; jl verif_click_in_patrat_x
					; jmp continuare
					
					; verif_click_in_patrat_x:
						; mov eax,[ebp+arg2] ;coordonate x
						; cmp eax,150
						; jg verif_click_in_patrat_x_1
						; jmp continuare
						
						; verif_click_in_patrat_x_1:
							; cmp eax,600
							; jl identificare_j ;am dat click in patrat
							; jmp continuare
							
	;gasim i si j
	; mov ecx,9
	; identificare_j:
		; mov eax, [ebp+arg3] ;coordonate y
		; mov edx, 250
		; cmp eax, edx
		; jl identificare_i
		; jmp identificare_j_1
		
		
		
	; identificare_j_1:
		; inc j
		; add edx,50
		; cmp eax,edx
		; jl identificare_i
		; loop identificare_j_1
	; mov ecx,9
	; identificare_i :
		; mov eax, [ebp+arg2] ;coordante x
		; mov edx, 200
		; cmp eax,edx
		; jl continuare
		; jmp identificare_i_1
		
	; identificare_i_1:
			; inc i
			; add edx,50
			; cmp eax,edx
			; jl continuare
			; loop identificare_i_1
	
	; continuare: 
			; push j
			; push i
			; push offset mesaje
			; call printf
			; add esp,12
	
	; pusha
		; mov ebx,[ebp+arg2]
		; mov mouseX, ebx
		; mov ecx,[ebp+arg3]
		; mov mouseY,ecx
	; popa
	
		; make_text_macro tasta, area, mouseX, mouseY

	
	; mov edi, area
	; mov ecx, area_height
	; mov ebx, [ebp+arg3]
	; and ebx, 24
	; inc ebx
	
	;inc matrice_de_afisat[eax]
	push eax
	push eax
	push offset mesaje
	call printf
	add esp,12
	popa

evt_timer :
	inc counter
afisare_litere:
	;afisam valoarea counter-ului curent (sute, zeci si unitati)
	mov ebx, 10
	mov eax, counter
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 30, 10
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 20, 10
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 10, 10
	
	;scriem un mesaj
	
	;make_text_macro tasta, area, mouseX, mouseY
	
	make_text_macro 'P', area, 190, 34
	make_text_macro 'R', area, 200, 34
	make_text_macro 'O', area, 210, 34
	make_text_macro 'I', area, 220, 34
	make_text_macro 'E', area, 230, 34
	make_text_macro 'C', area, 240, 34
	make_text_macro 'T', area, 250, 34
	
	make_text_macro 'L', area, 300, 34
	make_text_macro 'A', area, 310, 34
	
	make_text_macro 'A', area, 360, 34
	make_text_macro 'S', area, 370, 34
	make_text_macro 'A', area, 380, 34
	make_text_macro 'M', area, 390, 34
	make_text_macro 'B', area, 400, 34
	make_text_macro 'L', area, 410, 34
	make_text_macro 'A', area, 420, 34
	make_text_macro 'R', area, 430, 34
	make_text_macro 'E', area, 440, 34
	M_afisare_careu
	
	line_horizontal button_x, button_y, button_size, 0
	line_horizontal button_x, button_y + button_size, button_size, 0
	line_vertical button_x, button_y, button_size, 0
	line_vertical button_x + button_size, button_y, button_size, 0
	mov edx, 0
	mov ecx, 9
	mov edx, 250
	; pusha
	; push offset	vertical
	; call puts
	;add esp, 4
	;popa
 bucla :
	
	pusha 
	line_horizontal button_x, edx, 450, 0 
	popa
	add edx, 50
	loop bucla
	line_horizontal 150,199,450 ,0 ;se ingroasa prima linie
	line_horizontal 150,201,450 ,0 ;se ingroasa prima linie	
	line_horizontal 150,649,450 ,0 ;se ingroasa ultima linie
	line_horizontal 150,651,450 ,0 ;se ingroasa ultima linie
	line_horizontal 150,349,450 ,0 ;se ingroasa a treia linie de sus in jos
	line_horizontal 150,351,450 ,0 ;se ingroasa a treia linie de sus in jos
	line_horizontal 150,499,450 ,0 ;se ingroasa a sasea linie de sus in jos
	line_horizontal 150,501,450 ,0 ;se ingroasa a sasea linie de sus in jos
	line_vertical 200,200,450 ,0 ;se formeaza linia verticala
	line_vertical 250,200,450 ,0 ;se formeaza linia verticala
	line_vertical 299,200,450 ,0 ;se ingroasa a treia linie de la stanga la dreapta
	line_vertical 300,200,450 ,0 ;se formeaza linia verticala
	line_vertical 301,200,450 ,0 ;se ingroasa a treia linie de la stanga la dreapta
	line_vertical 350,200,450 ,0 ;se formeaza linia verticala
	line_vertical 400,200,450 ,0 ;se formeaza linia verticala
	line_vertical 449,200,450 ,0 ;se ingroasa a sasea linie de la stanga la dreapta
	line_vertical 450,200,450 ,0 ;se formeaza linia verticala
	line_vertical 451,200,450 ,0 ;se ingroasa a sasea linie de la stanga la dreapta
	line_vertical 500,200,450 ,0 ;se formeaza linia verticala
	line_vertical 550,200,450 ,0 ;se formeaza linia verticala
	line_vertical 599,200,450,0 ;se ingroasa prima linie din dreapta
	line_vertical 601,200,450,0 ;se ingroasa prima linie din dreapta
	line_vertical 149,200,450,0 ;se ingroasa prima linie din stanga
	line_vertical 151,200,450,0 ;se ingroasa prima linie din stanga
	
	line_horizontal 685,79,70,04225h
	line_horizontal 685,139,70,04225h
	line_vertical 685, 79, 60,04225h
	line_vertical 755,79, 60, 04225h
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start