import pygame 
import sys
import random
import math

BLOCK_NUM = 4
CYCLE_NUM = 4
TARGET_POS = [0, 45, 90, 135, 180, 225, 270, 315]
TARGET_DISTANCE = 180

SCREEN_SIZE = (640, 480)
SCREEN_CENTER = (int(SCREEN_SIZE[0] / 2), int(SCREEN_SIZE[1] / 2))

def main():
    #get subject name 
    sbjName = input('Input subject name: ')

    pygame.init()
    screen = pygame.display.set_mode(SCREEN_SIZE)
    pygame.display.update()

    for block in range(BLOCK_NUM):
        ready(screen)
        for cycle in range(CYCLE_NUM):
            random.shuffle(TARGET_POS)
            for target in TARGET_POS:
                task(screen, block, cycle, target)
    return

def ready(screen):
    screen.fill((0, 0, 0))
    sysfont = pygame.font.SysFont(None, 40)
    text = sysfont.render("PRESS ENTER", True, (255, 255, 255))
    while True:
        screen.blit(text, (320, 240))
        pygame.display.update()
        for e in pygame.event.get():
            if e.type == pygame.QUIT:
                return
            if (e.type == pygame.KEYDOWN and e.key == pygame.K_RETURN):
                print("success")
                return

def task(screen, block, cycle, target):
    clock = pygame.time.Clock()
    sysfont = pygame.font.SysFont(None, 40)
    text = sysfont.render(str(target), True, (255, 255, 255))
    print("block: {0}, cycle: {1}".format(block, cycle))
    while True:
        clock.tick(100)
        if block % 2:
            screen.fill((0, 0, 0))
        else:
            screen.fill((255, 0, 0))
        targetPosition = (
            int(SCREEN_CENTER[0] + TARGET_DISTANCE * math.cos(math.radians(target))),
            int(SCREEN_CENTER[1] + TARGET_DISTANCE * math.sin(math.radians(target)))
        )
        pygame.draw.circle(screen, (255, 255, 255), targetPosition, 10, 2)
        pygame.draw.circle(screen, (255, 255, 255), SCREEN_CENTER, 10, 2)
        screen.blit(text, (320, 240))
        pygame.display.update()
        for e in pygame.event.get():
            if e.type == pygame.QUIT:
                sys.exit()
                return
            if (e.type == pygame.KEYDOWN and e.key == pygame.K_RETURN):
                return

if __name__ == "__main__":
    main()