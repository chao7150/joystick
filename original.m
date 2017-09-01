% joystick rotate task program for ogawa-san's task
%
% requirement
%   Psychtoolbox
%   Joystick(HID device)
%
% history
% 2012.01.12 start
% 2012.01.23 first release
% 
%
% How to plot the data
%
% >> load FNAME.mat
% >> X = save_pos(1,:);
% >> Y = save_pos(2.:);
% >> T = save_pos(3,:);
% >> plot(T,X);
% >> plot(T,Y);
% >> plot(X,Y);
% 

function rotJoy
    clear all;
    global task; %task
    global scr;
    global kbd;
    global joy;
    global flg;
    tmp_save_pos = zeros(3,100000);
    datCnt = 1;
    tmp_save_rot_pos = zeros(2,100000);
    
    %get subject name
    while(1)
        task.sbjName = input('Input subject name.\n','s');
        if (size(task.sbjName,2) >= 1)
            [task.saveFName,isCntMax] = findSaveFName(task.sbjName,100000);  %numbering
            if isCntMax
                fprintf('[ERROR] The number of the data arrived at the maximum.\n');
                return;
            else
                break;  %input OK
            end
        else
            fprintf('error! Please input a longer name.\n');
        end
    end
    fprintf('Please wait... \n');
    
    % Removes the blue screen flash and minimize extraneous warnings.
	Screen('Preference', 'VisualDebugLevel', 3);
    Screen('Preference', 'SuppressAllWarnings', 1);

    initFlg;
    %input settings(Key)
    initKey;
    % disable the particular keys.
    DisableKeysForKbCheck([243,244,173,174,175,16,160,161]);
    [ keyIsDown, seconds, keyCode ] = KbCheck;

    % Find out how many screens and use largest screen number.
    scrNo = max(Screen('Screens'));
    black = BlackIndex(scrNo);
    white = WhiteIndex(scrNo);
    bgColor = black;
    foreColor = white;
    txtBase = 1; % text baseline
    
    % Open a new window.
    if flg.fullScr
        [wnd,wndRect] = Screen('OpenWindow', scrNo, black);
    else
        [wnd,wndRect] = Screen('OpenWindow', scrNo, black, [100 100 900 700]);
    end
    scr.rect = wndRect;
    scr.width = wndRect(3)-wndRect(1);
    scr.height = wndRect(4)-wndRect(2);
    scr.cX = scr.width/2;
    scr.cY = scr.height/2;
    scr.limXY = 300; %limit of moving cursor(pixel)
    
    % free margin for center
    scr.freeMargin = 30; %pixels
    
    % position of show reward
    scr.rewX = scr.width/2 - 50;
    scr.rewY = scr.cY + 200;
    scr.resultX = scr.width/2 - 50;
    scr.resultY = scr.cY + 180;
    
    %color of viewpint
    scr.col.viewpoint = [255 255 255];
    scr.col.cuePlus = [0 0 255];
    scr.col.cueMinus = [255 0 0];
    
    % initialize
    initVal;
    initTask;
    
    % init messages
    scr.msg.now = task.msg.start;
    [tmpShowRect , tmpOffShowRect] = Screen('TextBounds', wnd, scr.msg.now);  % text centering
    scr.showMsgX = scr.cX - (tmpShowRect(3) / 2);
    scr.showMsgY = scr.cY + 30;

    % init Joystick
    if flg.dummyInput
        [joy.mX, joy.mY, joy.btn] = GetMouse;
    else
        tmpJoyCaps = getJoyCaps(0);   %0:JoystickID_1, 1:JoystickID_2
        joy.scaleX = (scr.limXY*2) / (tmpJoyCaps.wXmax - tmpJoyCaps.wXmin);
        joy.scaleY = (scr.limXY*2) / (tmpJoyCaps.wYmax - tmpJoyCaps.wYmin);
    end      
    joy.offsetX = scr.limXY;
    joy.offsetY = scr.limXY;
    
    % Set text display options. We skip on Linux.
    if ~IsLinux
        Screen('TextFont', wnd, 'Arial');
        Screen('TextSize', wnd, 14);
    end

    HideCursor; %mouseCursor
    tmpMsg = sprintf('WAIT TRIGGER');
    [tmpRect , tmpOffRect] = Screen('TextBounds', wnd, tmpMsg);  % text centering
    scr.msgX = (scr.width-tmpRect(3))/2;
    scr.msgY = scr.cY;
    Screen('DrawText', wnd, tmpMsg, scr.msgX,  scr.msgY, white);
    tmpMsg = sprintf('(or PRESS ENTER TO START)');
    [tmpRect , tmpOffRect] = Screen('TextBounds', wnd, tmpMsg);
    scr.msgX = (scr.width-tmpRect(3))/2;
    scr.msgY = scr.cY + 30;
    Screen('DrawText', wnd, tmpMsg, scr.msgX,  scr.msgY, white);
    
    Screen('Flip', wnd);
    
    % ready to start (wait trigger)
    while (1)
        [ keyIsDown, seconds, keyCode ] = KbCheck;
        if (keyCode(kbd.trigger) || keyCode(kbd.enter)) %WAIT TRIGGER
            break;
        end
        if keyCode(kbd.esc) %Press ESC to exit program
            Screen('CloseAll');
            ShowCursor; %mouseCursor
            fprintf('\nabort.\n');
            return;
        end
    end
    
    Screen('Flip', wnd);
    %WaitSecs(2.0);
    
    %counter initialize
    trNow = 1;
    trNext = trNow + 1;
    
    %block and trials
    blCnt = 1;
    trCnt = 1;

    % timing initialize
    tim.taskStart = floor(GetSecs * 1000.0);
    tim.now = 0;
    tim.old = tim.now;
    
    tim.trEnd = task.tr(trNow).endTim;
    
    tmpRotRad = 0; %radian

    % task start
    while ~keyCode(kbd.esc)
        [ keyIsDown, seconds, keyCode ] = KbCheck;
        if flg.dummyInput
            [joy.mX, joy.mY, joy.btn] = GetMouse;
        else
            %%% how to check:  type "test=getJoyVal(0)" matlab prompt
            tmpJoy = getJoyVal(0); 
            joy.mX = tmpJoy.wXpos;
            joy.mY = tmpJoy.wYpos;
            joy.btn = tmpJoy.wButtons;
        end %if

        % joystick position
        if flg.dummyInput
            tmpCurX = joy.mX-scr.cX;
            tmpCurY = joy.mY-scr.cY;
        else
            tmpCurX = joy.scaleX * joy.mX -joy.offsetX;
            tmpCurY = joy.scaleX * joy.mY -joy.offsetY;
        end %if
        
        % free (for centering)
        if flg.use_free_margin
            tmpDist = hypot([tmpCurX tmpCurY],[0 0]);
            if scr.freeMargin > tmpDist
                tmpCurX = 0;
                tmpCurY = 0;
            end
        end
        
        % coordinate transformation
        [TH,R]=cart2pol(tmpCurX, -tmpCurY);
        [curX,curY]=pol2cart(-TH, R);
        [rotCurX,rotCurY]=pol2cart(-TH + tmpRotRad, R);
        if (flg.chkDist)
            if tmpMaxR < R
                tmpMaxR = R;
                tmpMaxTH = -TH + tmpRotRad;
            end
        end

        %save position
        tmp_save_pos(1,datCnt) = tmpCurX;
        tmp_save_pos(2,datCnt) = tmpCurY;
        tmp_save_pos(3,datCnt) = tim.now;
        tmp_save_rot_pos(1,datCnt) = rotCurX;
        tmp_save_rot_pos(2,datCnt) = rotCurY;
        datCnt = datCnt + 1;
        
        %%% timer update %%%
        tim.old = tim.now;
        tim.now = floor((GetSecs * 1000.0) - tim.taskStart);
        
        %%% events %%%
        if (tim.now >= tim.trEnd)
            switch task.tr(trNow).setState
            case 1 %start
                fprintf('%d end of START \n',tim.now);
                flg.showMsg = 0;
            case 2 %block
                switch task.tr(trNow).blockState
                case 1 %cue
                    fprintf('%d end of CUE \n',tim.now);
                    flg.showMsg = 0;
                case 2 %ready
                    fprintf('%d end of READY \n',tim.now);
                case 3 %trial
                    switch task.tr(trNow).trialState
                    case 1 %target
                        fprintf('%d end of TARGET \n',tim.now);
                        flg.chkDist = 0;
                    case 2 %feedback
                        fprintf('%d end of FEEDBACK \n',tim.now);
                        flg.showTarget = 0;
                        flg.showFeedback = 0;
                        
                        task.log(blCnt, trCnt).feedbackEndCnt = (datCnt - 1); %log data
                        
                        tmpStart = task.log(blCnt, trCnt).targetStartCnt;
                        tmpEnd = task.log(blCnt, trCnt).feedbackEndCnt;
                        task.log(blCnt, trCnt).moves = tmp_save_pos(:,tmpStart:tmpEnd);
                        task.log(blCnt, trCnt).rotMoves = tmp_save_rot_pos(:,tmpStart:tmpEnd);
                    case 3 %wait
                        fprintf('%d end of WAIT \n',tim.now);
                        trCnt = trCnt + 1;  %trial count up
                    end
                case 4 %rest
                    fprintf('%d end of REST \n',tim.now);
                    flg.showMsg = 0;
                    trCnt = 1;  %trial count reset
                    blCnt = blCnt + 1;  %block count up
                end
            case 3 %finish
            	fprintf('%d end of TASK FINISH \n',tim.now);
                flg.showMsg = 0;
            	break; %exit Main Task
            end
            
            % changes for the next state
            switch task.tr(trNext).setState
            case 2 %block
                switch task.tr(trNext).blockState
                case 1 %cue
                    fprintf('%d start of CUE \n',tim.now);
                    scr.col.oldview = scr.col.viewpoint;  %save prev
                    if task.tr(trNext).cue.deg >= 0;  %plus
                        scr.col.viewpoint = scr.col.cuePlus;
                    else
                        scr.col.viewpoint = scr.col.cueMinus;
                    end
                    tmpRotRad = task.tr(trNext).cue.deg * 0.0175;  %%% pi/180=0.0175
                    %show cue message
                    scr.msg.now = task.msg.cue;
                    [tmpShowRect , tmpOffShowRect] = Screen('TextBounds', wnd, scr.msg.now);  % text centering
                    scr.showMsgX = scr.cX - (tmpShowRect(3) / 2);
                    flg.showMsg = 1;
                case 2 %ready
                    fprintf('%d start of READY \n',tim.now);
                    scr.col.viewpoint = scr.col.oldview;  %restore prev
                case 3 %trial
                    switch task.tr(trNext).trialState
                    case 1 %target
                        fprintf('%d start of TARGET \n',tim.now);
                        flg.showTarget = 1;
                        tmpTarRect = task.tr(trNext).tar.rect;
                        tmpMaxR = 0;  % distance from center to cursor
                        tmpMaxTH = 0;
                        flg.chkDist = 1;
                        
                        task.log(blCnt, trCnt).targetStartCnt = (datCnt - 1); %log data
                    case 2 %feedback
                        fprintf('%d start of FEEDBACK \n',tim.now);
                        [tmpMaxX,tmpMaxY]=pol2cart(tmpMaxTH, tmpMaxR);
                        %save data
                        task.tr(trNext).maxR = tmpMaxR;
                        task.tr(trNext).maxTH = tmpMaxTH;
                        task.tr(trNext).maxX = tmpMaxX;
                        task.tr(trNext).maxY = tmpMaxY;
                        task.log(blCnt, trCnt).maxCurPol = [tmpMaxTH tmpMaxR];  %log data
                        task.log(blCnt, trCnt).maxCurCart = [tmpMaxX tmpMaxY];  %log data
                        
                        %errAngle
                        tmpMaxDeg = tmpMaxTH * 180 / pi;  % rad to deg
                        tmpTarDeg = task.log(blCnt, trCnt).tarDeg;
                        task.log(blCnt, trCnt).errAngle = tmpMaxDeg - tmpTarDeg;
                        
                        %errDistance
                        tmpDiff = task.log(blCnt, trCnt).tarPos - task.log(blCnt, trCnt).maxCurCart; %[diffX, diffY]
                        task.log(blCnt, trCnt).errDistance = hypot(tmpDiff(1),tmpDiff(2));  % calc distance
                        
                        flg.showFeedback = 1;
                    case 3 %wait
                        fprintf('%d start of WAIT \n',tim.now);
                    end
                case 4 %rest
                    fprintf('%d start of REST \n',tim.now);
                    %show rest message
                    scr.msg.now = task.msg.rest;
                    [tmpShowRect , tmpOffShowRect] = Screen('TextBounds', wnd, scr.msg.now);  % text centering
                    scr.showMsgX = scr.cX - (tmpShowRect(3) / 2);
                    flg.showMsg = 1;
                end
            case 3 %finish
            	fprintf('%d start of TASK FINISH \n',tim.now);
                %show rest message
                scr.msg.now = task.msg.finish;
                [tmpShowRect , tmpOffShowRect] = Screen('TextBounds', wnd, scr.msg.now);  % text centering
                scr.showMsgX = scr.cX - (tmpShowRect(3) / 2);
                flg.showMsg = 1;
            end
            
            trNow = trNext;
            trNext = trNext + 1;
            tim.trEnd = task.tr(trNow).endTim;
        end %events
        
        %%% render screen %%%                
        %target position
        if flg.showTarget
            drawTarget(wnd,tmpTarRect);
        end
        
        % cursors
        if (flg.showFeedback)
            drawCursor(wnd, tmpMaxX + scr.cX, tmpMaxY + scr.cY, [255 255 255]);
        end

        if (flg.showRotCursor && flg.debug)
            drawCursor(wnd, rotCurX + scr.cX, rotCurY + scr.cY, [0 128 0]);
        end
        
        if (flg.showCursor && flg.debug)
            drawCursor(wnd, curX + scr.cX, curY + scr.cY, [128 128 128]);
        end
        
        % fixation
        drawViewPoint(wnd, scr.col.viewpoint);
        
        % messages
        if flg.showMsg
            Screen('DrawText', wnd, scr.msg.now, scr.showMsgX,  scr.showMsgY, [255 255 255]);
        end
          
        if flg.debug %DEBUG
            tmpMsg = sprintf('cur=[%d,%d]',curX,curY);
            [tmpRect , tmpOffRect] = Screen('TextBounds', wnd, tmpMsg);
            debugMsgX = 10;
            debugMsgY = 40;
            Screen('DrawText', wnd, tmpMsg, debugMsgX,  debugMsgY, white);
            
            tmpMsg = sprintf('rotCur=[%d,%d]',rotCurX,rotCurY);
            [tmpRect , tmpOffRect] = Screen('TextBounds', wnd, tmpMsg);
            debugMsgX = 10;
            debugMsgY = 10;
            Screen('DrawText', wnd, tmpMsg, debugMsgX,  debugMsgY, white);
        end
        Screen('Flip', wnd);
        
    end %while
    %finish the program
    Screen('closeall')
    
    %save data
    if flg.savePos
        save_pos = tmp_save_pos(:,1:datCnt);
        save_rot_pos = tmp_save_rot_pos(:,1:datCnt);
        save(task.saveFName,'task','save_pos','save_rot_pos');
    else
        save(task.saveFName,'task');
    end    
return %function rotJoy


%%%%%%%%%%%%%%%%%
%%% functions %%%
%%%%%%%%%%%%%%%%%

function drawTarget(whnd,tRect)
    wid = 2;
    col = [255 255 255];
    Screen('FrameOval', whnd, col, tRect, wid);
return


function drawCursor(whnd,x,y,col)
    l = 10;
    wid = 3;
    %X
    %Screen('DrawLine', whnd, col, x-l, y-l, x+l, y+l, wid);
    %Screen('DrawLine', whnd, col, x-l, y+l, x+l, y-l, wid);
    %+
    Screen('DrawLine', whnd, col, x-l, y, x+l, y, wid);
    Screen('DrawLine', whnd, col, x, y+l, x, y-l, wid);
return


function drawViewPoint(whnd,col)
global scr;
    L=10;
    wid = 3;
    Screen('DrawLine', whnd, col, scr.cX-L, scr.cY, scr.cX+L, scr.cY, wid);
    Screen('DrawLine', whnd, col, scr.cX, scr.cY+L, scr.cX, scr.cY-L, wid);
return


function initKey
    global kbd;
    global joy;
    
    KbName('UnifyKeyNames');
    kbd.esc = KbName('ESCAPE');
    kbd.enter = KbName('Return');
    kbd.clear = KbName('c');
    kbd.trigger = KbName('t');
        
    % cursor (initialize)
    joy.mX = 0; % The x-coordinate of the mouse cursor
    joy.mY = 0; % The y-coordinate of the mouse cursor
    joy.btn = [0,0,0];
return %initKey


function initTask
global task;
global scr;

%random seed initialization
rand('state',sum(100*clock));

%sequence
baseTim = 0;
n = 1; sState = 1;  %setSate

%start
task.tr(n).setState = sState;
task.tr(n).dur = task.dur.start;
baseTim = baseTim + task.tr(n).dur;
task.tr(n).endTim = baseTim;
n = n + 1; sState = sState + 1;
fprintf('%d  end of start\n',baseTim);  %DEBUG

% degree of cue
tmpCueDeg = horzcat(task.cueDeg,task.cueDeg,task.cueDeg,task.cueDeg,task.cueDeg);

%block
for p = 1:task.blockNum
    fprintf('%d  block\n',p);  %DEBUG
    bState = 1;  %blockState
    %cue
    tmpLogCueStartTim = baseTim;  % for log
    tmpLogCueDeg = tmpCueDeg(p);  % for log    
    
    task.tr(n).cue.deg = tmpCueDeg(p);
    task.tr(n).setState = sState;
    task.tr(n).blockState = bState;
    task.tr(n).dur = task.dur.cue;    
    baseTim = baseTim + task.tr(n).dur;
    task.tr(n).endTim = baseTim;
    n = n + 1; bState = bState + 1;   %counter increase (trial, block)
    fprintf('%d  end of cue\n',baseTim);  %DEBUG
    
    %ready
    tmpLogReadyStartTim = baseTim;  % for logeTim;
    
    task.tr(n).cue.deg = tmpCueDeg(p);
    task.tr(n).setState = sState;
    task.tr(n).blockState = bState;
    task.tr(n).dur = task.dur.ready;
    baseTim = baseTim + task.tr(n).dur;
    task.tr(n).endTim = baseTim;
    n = n + 1; bState = bState + 1;   %counter increase (trial, block)
    fprintf('%d  end of ready\n',baseTim);  %DEBUG
    
    %trial
    % randomize of wait duration
    tmpWait = horzcat(task.dur.wait, task.dur.wait);
    task.wait(p).seq = horzcat(tmpWait(randperm(size(tmpWait,2))),tmpWait(randperm(size(tmpWait,2))));
    fprintf('wait duration pattern:');  %DEBUG
    task.wait(p).seq / 1000   %DEBUG
    
    % randomize of the target direction
    tmpTar = task.tarDeg;
    task.wait(p).tarDeg = horzcat(tmpTar(randperm(size(tmpTar,2))),tmpTar(randperm(size(tmpTar,2))));
    fprintf('target arrival pattern (degree):');  %DEBUG
    task.wait(p).tarDeg  %DEBUG
    
    for q = 1:task.trialNum
        fprintf('%d-%d  trial\n',p, q);  %DEBUG
        tState = 1;  %targetState
        %calculation of the target position
        task.tr(n).tar.deg = task.wait(p).tarDeg(q);
        th = (task.tr(n).tar.deg*pi)/180;
        task.tr(n).tar.x = task.tarDist * cos(th);
        task.tr(n).tar.y = task.tarDist * -sin(th);
        x1 = scr.cX + task.tarDist * cos(th) - task.tarR;
        y1 = scr.cY - task.tarDist * sin(th) - task.tarR;
        x2 = scr.cX + task.tarDist * cos(th) + task.tarR;
        y2 = scr.cY - task.tarDist * sin(th) + task.tarR;
        task.tr(n).tar.rect=[x1 y1 x2 y2];
        
        tmpLogTargetStartTim = baseTim;  % for logTim;
        tmpLogTargetDegree = task.tr(n).tar.deg; % for logTim;
        tmpLogTargetRect = [x1 y1 x2 y2];
        tmpLogTargetPos = [task.tr(n).tar.x task.tr(n).tar.y];
        
        task.tr(n).cue.deg = tmpCueDeg(p);
        task.tr(n).setState = sState;
        task.tr(n).blockState = bState;
        task.tr(n).trialState = tState;
        task.tr(n).dur = task.dur.target;
        
        %timing update
        baseTim = baseTim + task.tr(n).dur;
        task.tr(n).endTim = baseTim;
        n = n + 1; tState = tState + 1;   %trial counter increase
        fprintf('%d  end of target\n',baseTim);  %DEBUG
        
        %feedback
        tmpLogFeedbackStartTim = baseTim;  % for logTim;
        
        task.tr(n).setState = sState;
        task.tr(n).blockState = bState;
        task.tr(n).trialState = tState;
        task.tr(n).dur = task.dur.feedback;
        baseTim = baseTim + task.tr(n).dur;
        task.tr(n).endTim = baseTim;
        n = n + 1; tState = tState + 1;   %trial counter increase
        fprintf('%d  end of feedback\n',baseTim);  %DEBUG

        %wait
        tmpLogWaitStartTim = baseTim;  % for logTim;
        
        task.tr(n).setState = sState;
        task.tr(n).blockState = bState;
        task.tr(n).trialState = tState;
        task.tr(n).dur = task.wait(p).seq(q);
        baseTim = baseTim + task.tr(n).dur;
        task.tr(n).endTim = baseTim;
        n = n + 1;   %trial counter increase
        fprintf('%d  end of wait\n',baseTim);  %DEBUG
        tmpLogTrialEndTim = baseTim;  % for logTim;
        
        %log data
        task.log(p, q).cueDeg = tmpLogCueDeg;
        task.log(p, q).tarDeg = tmpLogTargetDegree;
        task.log(p, q).tarPos = tmpLogTargetPos;
        task.log(p, q).tarRect = tmpLogTargetRect;
        task.log(p, q).maxCurPol = [];  %radian  (to deg: *180/pi)
        task.log(p, q).maxCurCart = [];
        task.log(p, q).errAngle = [];  %2012.02.01 add
        task.log(p, q).errDistance = [];   %2012.02.01 add
        task.log(p, q).cueStartTim  = tmpLogCueStartTim;
        task.log(p, q).readyStartTim  = tmpLogReadyStartTim;
        task.log(p, q).targetStartTim  = tmpLogTargetStartTim;
        task.log(p, q).feedbackStartTim  = tmpLogFeedbackStartTim;
        task.log(p, q).waitStartTim  = tmpLogWaitStartTim;
        task.log(p, q).trialEndTim  = tmpLogTrialEndTim;
        task.log(p, q).targetStartCnt = [];
        task.log(p, q).feedbackEndCnt = [];
        task.log(p, q).moves = [];
    end
    bState = bState + 1;   %block counter increase
    
    %rest
    task.tr(n).setState = sState;
    task.tr(n).blockState = bState;
    task.tr(n).dur = task.dur.rest;
    baseTim = baseTim + task.tr(n).dur;
    task.tr(n).endTim = baseTim;
    n = n + 1;
    fprintf('%d  end of rest\n',baseTim);  %DEBUG
end
sState = sState + 1;  %set counter increase

%finish
task.tr(n).setState = sState;
task.tr(n).dur = task.dur.finish;
baseTim = baseTim + task.tr(n).dur;
task.tr(n).endTim = baseTim;
fprintf('%d  finish\n',baseTim);  %DEBUG
return


function [retFName,reached] = findSaveFName(sbj,maxNo)
    tmpFNo = 1;
    reached = 0;
    %mkdir('data');
    for ii=1:maxNo
        retFName = sprintf('data/%s%03d.mat',sbj,tmpFNo);
        fp = fopen(retFName,'r+');
        if fp > 0
            fclose(fp);
            tmpFNo = tmpFNo + 1;
        else
            break; % found file number
        end %if
    end %while
    if ii >= maxNo
        reached = 1;  %fprintf('[ERROR] The number of the data arrived at the maximum.\n');
        return;
    end %if
return %findSaveFName


function initVal
global task;
% status
task.blockNum = 10;
task.trialNum = 3;

% duration
task.dur.start = 3.0 * 1000;
task.dur.cue = 1.0 * 1000;
task.dur.ready = 4.0 * 1000;
task.dur.target = 1.0 * 1000;
task.dur.feedback = 1.0 * 1000;
task.dur.wait = [2.0 3.0 4.0 5.0] * 1000;  %randomize rater
task.dur.rest = 1.0 * 1000;
task.dur.finish = 3.0 * 1000;

% messages
task.msg.start = 'START';
task.msg.cue = ' ';
task.msg.rest = 'END';
%task.msg.rest = 'REST';
task.msg.finish = 'TASK FINISH';

%%% directions (task.order)
    task.tarDeg=[90,270,180,360,135,315,225,45];   % degree of targets
%%%   5 1 8
%%%  3  *  4
%%%   7 2 6
    task.tarDist = 120.0;   % distance between center and target(pixel)
    task.tarR = 10.0;       % radius of the target(pixel)

%%% rotation(cue) 
    task.cueDeg = [+45, -45];  %degree
    %task.cueDeg = [0, -45];  %degree
return


function initFlg
global flg;
    flg.dummyInput = 0; % 0:joystick, 1:mouse
    flg.fullScr = 1; % 0:window, 1:fullscreen, 2:external display
    flg.savePos = 1; % 0:do not save position data, 1:save
    flg.use_free_margin = 0; % 0:no use free mergin, 1:use
    flg.debug = 1;   % 0: release, 1:debug
    
    %for debug
    flg.showCursor = 1;
    flg.showRotCursor = 1;
    
    %status (DO NOT CHANGE!)
    flg.showTarget = 0;
    flg.chkDist = 0;
    flg.showFeedback = 0;
    flg.showMsg = 1;
return %drawCursor


    
    
    