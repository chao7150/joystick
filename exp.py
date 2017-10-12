import pygame
import sys, os, shutil
import random
import math
import csv
from datetime import datetime

#様々な定数の決定
BLOCK_NUM = 1
CYCLE_NUM = 1
TARGET_POS = [i*45 for i in range(8)]
TARGET_DISTANCE = 300
RADIUS = 15

SCREEN_SIZE = (1000, 750)
SCREEN_CENTER = (int(SCREEN_SIZE[0] / 2), int(SCREEN_SIZE[1] / 2))
JOYSTICK_SCALE = 350

FPS = 60
ROTATE_ANGLE = [40, -40]
TIMELIMIT = 80
WAITTIME = 50
OFFSET = 1

#2点間の距離を計算する関数。あちこちで使うので定義しておく。
def distance(p1, p2):
    return ((p1[0] - p2[0]) ** 2 + (p1[1] - p2[1]) ** 2) ** 0.5


#ここから始まる
def main():
    #get subject name
    sbjName = input('Input subject name: ')
    #もろもろの初期化。最初に１回やればいい。
    recorder = Recorder(sbjName)
    pygame.init()
    joystick = pygame.joystick.Joystick(0)
    joystick.init()
    screen = pygame.display.set_mode(SCREEN_SIZE)
    pygame.display.update()

    #ブロック・サイクルの構造はここに集約しておく。ブロックが終わるたびにready()に飛んで休憩させる。
    for block in range(BLOCK_NUM):
        ready(screen)
        for cycle in range(CYCLE_NUM):
            #１サイクルごとにターゲット位置のリストをシャッフルする
            random.shuffle(TARGET_POS)
            for target in TARGET_POS:
                recorder.append(task(screen, recorder, joystick, block, cycle, target))
    recorder.end()
    return

#単純に参加者がボタンを押すまで待つだけ
def ready(screen):
    #最初に画面を黒で塗りつぶす（前の試行の画面を消す）
    screen.fill((0, 0, 0))
    #文字を表示するための準備
    sysfont = pygame.font.SysFont(None, 50)
    text = sysfont.render("PRESS ANY BOTTON", True, (255, 255, 255))
    #無限ループ
    while True:
        #準備した文字を表示する
        pygame.event.pump()
        screen.blit(text, (SCREEN_CENTER[0]-180,SCREEN_CENTER[1]))
        pygame.display.update()
        for e in pygame.event.get():
            #ウィンドウ左上の終了ボタンが押されたらプログラムを終了する
            if e.type == pygame.QUIT:
                sys.exit()
            #ボタンが押されたらmain()に戻る
            if e.type == pygame.JOYBUTTONUP:
                return

#一回一回の課題の内容をここで定義する
def task(screen, recorder, joystick, block, cycle, target):
    #FPS設定の準備
    clock = pygame.time.Clock()
    #文字表示の準備
    sysfont = pygame.font.SysFont(None, 40)
    text = sysfont.render(str(target), True, (255, 255, 255))
    #print("block: {0}, cycle: {1}".format(block, cycle))
    #時間制限をつけるため、最初に許容フレーム数を入れておいてカウントダウンする
    remainingTime = TIMELIMIT
    frame = OFFSET
    tmplog = []
    #カウントダウンタイマーが0より大きい限り繰り返す
    while remainingTime > 0:
        #FPSの設定
        clock.tick_busy_loop(FPS)

        if block % 2:
            screen.fill((0, 0, 0))
        else:
            screen.fill((100, 0, 0))
        #ターゲットの位置を計算
        targetPosition = (
              int(SCREEN_CENTER[0] + TARGET_DISTANCE * math.cos(math.radians(target))),
              int(SCREEN_CENTER[1] + TARGET_DISTANCE * math.sin(math.radians(target)))
          )
        #ターゲットの描画
        pygame.draw.circle(screen, (255, 255, 255), targetPosition, RADIUS, 2)
        #中心点の描画
        pygame.draw.circle(screen, (255, 255, 255), SCREEN_CENTER, RADIUS, 2)
        # pygame.draw.line(screen, (255, 255, 255), (SCREEN_CENTER[0] - 200, SCREEN_CENTER[1]), (SCREEN_CENTER[0] + 200, SCREEN_CENTER[1]))
        # pygame.draw.line(screen, (255, 255, 255), (SCREEN_CENTER[0], SCREEN_CENTER[1] - 200), (SCREEN_CENTER[0], SCREEN_CENTER[1] + 200))
        # pygame.draw.line(screen, (255, 255, 255), (SCREEN_CENTER[0] - 300, SCREEN_CENTER[1] - 300), (SCREEN_CENTER[0] + 300, SCREEN_CENTER[1] + 300))
        # pygame.draw.line(screen, (255, 255, 255), (SCREEN_CENTER[0] + 300, SCREEN_CENTER[1] - 300), (SCREEN_CENTER[0] - 300, SCREEN_CENTER[1] + 300))
        #カーソルを描画しその座標をposに格納する
        pos = drawCursor(screen, joystick, block, False)
        tmplog.append([block, cycle, target, pos[0], pos[1]])
        #print(clock.get_fps())
        #screen.blit(text, (320, 240))
        dist = sysfont.render(str(distance(pos, SCREEN_CENTER)), True, (255, 255, 255))
        screen.blit(dist, (0, 0))

        pygame.display.update()
        #ループを一回繰り返すごとに（１フレームごとに）カウントダウンタイマーの値を１減らす
        remainingTime -= 1
        #接触判定。カーソルとターゲットの距離が10以下ならループの外に出る
        if distance(pos, targetPosition) < RADIUS:
            frame -= 1
            if frame == 0:
                break
        else:
            frame = OFFSET
        for e in pygame.event.get():
            #ウィンドウ左上の終了ボタンが押されたらプログラムを終了する
            if e.type == pygame.QUIT:
                sys.exit()
                return
            #エンターキーが押されたら課題を終了する（テスト用)
            if (e.type == pygame.KEYDOWN and e.key == pygame.K_RETURN):
                return

    respos = velocity(tmplog)
    respos = [
    (respos[0] - SCREEN_CENTER[0]) / distance(respos, SCREEN_CENTER) * TARGET_DISTANCE + SCREEN_CENTER[0],
    (respos[1] - SCREEN_CENTER[1]) / distance(respos, SCREEN_CENTER) * TARGET_DISTANCE + SCREEN_CENTER[1]
    ]
    dist1 = distance(SCREEN_CENTER, respos)
    dist2 = distance(SCREEN_CENTER, targetPosition)
    dist3 = distance(respos, targetPosition)
    error = math.degrees(math.acos((dist1 ** 2 + dist2 ** 2 - dist3 ** 2) / (2 * dist1 * dist2)))
    recorder.velappend([[block, cycle, targetPosition[0], targetPosition[1], respos[0], respos[1], error]])
    #ターゲットに接触するか時間制限に到達したらbackフェーズに入る。
    #一定時間（WAITTIME）中央にカーソルが置かれたら次の試行に入る
    waitTime = WAITTIME
    #waitTimeが0より大きい限り繰り返す
    while waitTime > 0:
        #FPSの設定
        clock.tick_busy_loop(FPS)
        if block % 2:
            screen.fill((0, 0, 0))
        else:
            screen.fill((100, 0, 0))
        #カーソルと画面中央の距離が１０ピクセル以下なら
        if distance(pos, SCREEN_CENTER) < RADIUS:
            #waitTimeを１減らす
            waitTime -= 1
            #中央を表す円の色を緑にする
            circleColor = (128, 255, 128)
        else:
            #カーソルが画面中央から離れるたびにwaitTimeを元に戻す（=中央に置き続けないと減らない）
            waitTime = WAITTIME
            #中央を表す円の色を赤にする
            circleColor = (255, 128, 128)
        pygame.draw.circle(screen, circleColor, SCREEN_CENTER, RADIUS, 2)
        pygame.draw.line(screen, (128, 128, 255), (respos[0] - 10, respos[1]), (respos[0] + 10, respos[1]), 2)
        pygame.draw.line(screen, (128, 128, 255), (respos[0], respos[1] - 10), (respos[0], respos[1] + 10), 2)
        pos = drawCursor(screen, joystick, block, True)
        pygame.display.update()
        #ウィンドウ左上の終了ボタンが押されたらプログラムを終了する
        for e in pygame.event.get():
            if e.type == pygame.QUIT:
                sys.exit()
                return
    return tmplog

#カーソルを描画するための関数
def drawCursor(screen, joystick, block, visible):
    #ブロックが奇数か偶数かで変換角度を変える
    rotateAngle = math.radians(ROTATE_ANGLE[0]) if block % 2 == 0 else math.radians(ROTATE_ANGLE[1])
    #ジョイスティックの値（-1 ~ 1）を取得し、原点が画面の中央に来るように標準化
    x = int(joystick.get_axis(0) * JOYSTICK_SCALE) + SCREEN_CENTER[0]
    y = int(joystick.get_axis(1) * JOYSTICK_SCALE) + SCREEN_CENTER[1]
    #回転変換（画面中央を中心に回転変換するため結構ややこしい）
    rx = int((x - SCREEN_CENTER[0]) * math.cos(rotateAngle) - (y - SCREEN_CENTER[1]) * math.sin(rotateAngle)) + SCREEN_CENTER[0]
    ry = int((x - SCREEN_CENTER[0]) * math.sin(rotateAngle) + (y - SCREEN_CENTER[1]) * math.cos(rotateAngle)) + SCREEN_CENTER[1]
    # pygame.draw.line(screen, (128, 128, 128), (x - 10, y), (x + 10, y), 2)
    # pygame.draw.line(screen, (128, 128, 128), (x, y - 10), (x, y + 10), 2)
    if visible:
        #カーソルを十字で表示するため、縦と横の線分を別々に描画する
        pygame.draw.line(screen, (255, 255, 255), (rx - 10, ry), (rx + 10, ry), 2)
        pygame.draw.line(screen, (255, 255, 255), (rx, ry - 10), (rx, ry + 10), 2)
    return (rx, ry)

def velocity(tmplog):
    vel = []
    for i in range(len(tmplog) - 1):
        vel.append([distance((tmplog[i][3], tmplog[i][4]), (tmplog[i + 1][3], tmplog[i + 1][4])), 0])
    index = vel.index(max(vel)) + 1
    return [tmplog[index][3], tmplog[index][4]]

class Recorder:

    def __init__(self, subjectName):
        self.log = []
        self.log.append(["block", "cycle", "target", "x", "y"])
        self.vel = []
        self.vel.append(["block", "cycle", "targetX", "targetY", "x", "y", "errordeg"])
        self.date = datetime.now().strftime("%Y%m%d-%H%M%S")
        self.dirname = 'results/' + self.date + subjectName
        os.makedirs(self.dirname)

    def append(self, d):
        self.log = self.log + d

    def velappend(self, d):
        self.vel = self.vel + d

    def end(self):
        logname = self.date + '.csv'
        with open(logname, 'w', newline = '') as f:
            writer = csv.writer(f)
            writer.writerows(self.log)
        velname = self.date + 'vel' + '.csv'
        with open(velname, 'w', newline = '') as f:
            writer = csv.writer(f)
            writer.writerows(self.vel)
        shutil.move(logname, self.dirname)
        shutil.move(velname, self.dirname)
        sys.exit()

if __name__ == "__main__":
    main()
