function sn76489()
% How to use:
% create the sub-directories wav\, bas\  and bin\
% put the .wav files to convert in wav\
% run the script, the converted data will be placed in bas\  and bin\
% 

close all

% https://www.smspower.org/Development/SN76489

path = 'wavs\';

names = dir([path '*.wav']);
nfiles = size(names,1);

Nvoices = 4;
Tntsc = 1/60;

FS = 8000;
Nntsc = fix(Tntsc*FS);
    
for ii = 1:nfiles 

    name = [ path names(ii).name];

    [Y,FFS] = audioread(name);
    
    if size(Y,2)>1
        X = Y(:,1)+Y(:,2);
    else
        X = Y;
    end

    [P, Q] = rat(FS/FFS);
        
    X = [zeros(round(2*Tntsc*FS),1) ; resample(X,P,Q)];
    
    figure(1);
    [fx,tt,pv,fv] = fxpefac(X,FS,Tntsc,'g');

    Nblk = length(fx);
  
    Y  = zeros((2+Nblk)*Nntsc,1);
    XX = zeros((2+Nblk)*Nntsc,1);
    
    f  = zeros(Nblk,Nvoices);
    a  = zeros(Nblk,Nvoices);

    FX = fx;
    PV = pv;

    Ndft = 2^16;

    for i=1:Nblk

        d = round((tt(i)-Tntsc/2)*FS);
        tti = d:(d+Nntsc-1);
        
        XF  =   abs(fft(X(tti),Ndft));

        Fmin = max(3579545/32/(2^10-1),FX(i)-1/Tntsc/2);                      % 109Hz -> about 1023 as period in SN76489
        
        [~,locs] = findpeaks(XF(1:round(Ndft/2)),'SORTSTR','descend'); 
        
%       [pks,locs] = findpeaks(XF(1:round(Ndft/2)),'SORTSTR','descend'); 

 %       j = find(locs> Fmin/FS*Ndft);
%        pks  = pks(j);
%        locs = locs(j);
        
        locs = locs(locs> Fmin/FS*Ndft);
        
        if size(locs,1)<Nvoices
            ti = (round(Ndft/2)-(Nvoices-1):round(Ndft/2))';
            ti(1:length(locs)) = locs;
            locs = ti;
        end

        locs = locs(1:Nvoices);     % choose the Nvoices strongest frequencies
                

        freq = (locs-1)/Ndft*FS;
        amp  = XF(locs)/sqrt(Ndft)/2;                   %         amp = pks(1:Nvoices)/sqrt(Ndft);

        fnoise = 3579545/2/16/30./[16 32 64];           % only 3 possible frequencies :  233.04        116.52         58.26]
        inoise = round(fnoise/FS*Ndft);                 % convert in index
        Anoise = XF(inoise)/sqrt(Ndft)/2;
        
        [~,ifn] = max(Anoise);                                             % choose the strongest
                
        freq(4) = fnoise(ifn);
        amp(4)  = Anoise(ifn);            % XF(round(freq(4)/FS*Ndft))/sqrt(Ndft);
                
        f(i,:) = freq;
        a(i,:) = amp;
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % compute simulated output
    % Coleco PSG SN76489
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    TP = uint16(round(3579545./(32*f)));
    a = a/max(a(:));

    nSN = zeros(size(a));
    for i=1:Nblk
        for j=1:Nvoices
            nSN(i,j) = min (15, fix(-10*log10(a(i,j))));
        end
    end
    
    for i=1:Nblk
        d = round((tt(i)-Tntsc/2)*FS);
        tti = d:(d+Nntsc-1);
        
        x = X(tti);
        t = tti'/FS;

        y = zeros(size(x));
        for  j=1:Nvoices
            y = y + sign(sin(2*pi*3579545/(32*double(TP(i,j)))*t)) * 10^(-nSN(i,j)/10)/10 * (nSN(i,j)~=15);
        end

        XX((i+1)*Nntsc+1:(i+2)*Nntsc) =  x;
        Y ((i+1)*Nntsc+1:(i+2)*Nntsc) =  y;
    end
    
    figure(1)
    subplot(5,1,1);
    plot((1:size(XX,1))/FS,XX,'r',(1:size(Y,1))/FS,Y,'b')

    org = audioplayer(XX,FS);
    playblocking(org);
    emu = audioplayer(Y,FS);
    playblocking(emu);
    
    [SNR,~] = snrseg(Y,XX,FS,'Vq',Tntsc);
    
    fprintf('file#%d  %s  snr = %2.2d dB\n',ii-1,names(ii).name,SNR)
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % write output
    % Coleco PSG SN76489
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
    
    name = [ 'bin\' names(ii).name];
    
    fid = fopen([name '_sn76489.bin'],'wb');
    for i = 1:Nblk
        for j = 1:3
            k = round(TP(i,j)+1024*nSN(i,j));
            fwrite(fid,k,'uint16');
        end
        q = TP(i,4)/16-1;
        q = min(2,q);
        k = q+uint16(1024*nSN(i,4));
        fwrite(fid,k,'uint16');
    end
    fwrite(fid,-1,'integer*2');    
    fclose(fid);
    
    name = [ 'bas\' names(ii).name];
    
    fid = fopen([name '_sn76489.bas'],'w');
    fprintf(fid,' REM sfx# %d : %s_sn76489.bas \n',ii-1,name);
    for i = 1:Nblk
        t = TP(i,1:Nvoices)+uint16(1024*nSN(i,1:Nvoices));
        q = TP(i,4)/16-1;
        q = min(2,q);
        t(4) = q+uint16(1024*nSN(i,4));
        fprintf(fid,' DATA $%4.4x,$%4.4x,$%4.4x,$%4.4x \n',t(1),t(2),t(3),t(4));
     end
     fprintf(fid,' DATA -1 \n');
     fclose(fid);
        
end

fid = fopen('sfx_sn76489.bas','w');
for ii=1:nfiles
    fprintf(fid,'SFX%d: INCLUDE "%s" \n',ii-1,['bas\' names(ii).name '_sn76489.bas'] );
end
fclose(fid);
 
%!copy wavs\*.bin C:\Users\Ragozzini\Documents\GitHub\uridium\afx

end
