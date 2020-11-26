rgbasm -o main.o src/main.asm
rgblink -o discbatter.gb main.o
rgbfix -v -p 0 -m 3 -r 1 -n 3 -t "DISC BATTER" discbatter.gb