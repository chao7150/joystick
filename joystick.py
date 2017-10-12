#! /usr/bin/env python
# coding: utf-8
# coding=utf-8
# -*- coding: utf-8 -*-
# vim: fileencoding=utf-8
import pygame
from pygame.locals import *

SCREEN_WIDTH = 640
SCREEN_HEIGHT = 480

pygame.joystick.init()
try:
    j = pygame.joystick.Joystick(0) # create a joystick instance
    j.init() # init instance
    print('Joystickの名称: ' + j.get_name())
    print('ボタン数 : ' + str(j.get_numbuttons()))
except pygame.error:
    print('Joystickが見つかりませんでした。')

def main():
    pygame.init()
    screen = pygame.display.set_mode( (SCREEN_WIDTH, SCREEN_HEIGHT) ) # 画面を作る
    pygame.display.set_caption('Joystick') # ()タイトル
    pygame.display.flip() # 画面を反映
    clock = pygame.time.Clock()

    while 1:
        screen.fill((0,0,0))
        pygame.event.pump()
        clock.tick(60)
        x , y = j.get_axis(0), j.get_axis(1)
        pygame.draw.circle(screen, (255,0,0), (int((x+1)*320),int((y+1)*240)), 10)
        print('x and y : ' + str(x) +' , '+ str(y))
        print(clock.get_fps())
        pygame.display.update()
        for event in pygame.event.get():

            if event.type == QUIT:
                sys.exit()

if __name__ == '__main__': main()
