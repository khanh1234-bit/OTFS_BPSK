close all;
clear all;
clc;

%% 1. Tham số mô phỏng
N = 10^6;               % Số lượng bit
SNR_dB = -10:2:30;      % Dải SNR (dB)
SNR_lin = 10.^(SNR_dB/10); 
len = length(SNR_dB);

% Tạo dữ liệu phát (BPSK: 1 -> 1, 0 -> -1)
x = randi([0,1], 1, N); 
x_in = 2*x - 1; 

% Khởi tạo mảng lưu kết quả
BER_SISO = zeros(1, len);
BER_SIMO_MRC = zeros(1, len);

%% 2. Vòng lặp SNR
for i = 1:len
    % --- Kênh truyền Rayleigh (Chuẩn hóa công suất về 1) ---
    h1 = (randn(1,N) + 1i*randn(1,N)) / sqrt(2); 
    h2 = (randn(1,N) + 1i*randn(1,N)) / sqrt(2); 
    
    % --- Tạo nhiễu Gaussian ---
    % Công suất nhiễu N0 = 1/SNR (với công suất tín hiệu Ps = 1)
    sigma = sqrt(1 / (2 * SNR_lin(i)));
    n1 = sigma * (randn(1,N) + 1i*randn(1,N));
    n2 = sigma * (randn(1,N) + 1i*randn(1,N));
    
    % --- Tín hiệu nhận ---
    y1 = h1 .* x_in + n1;
    y2 = h2 .* x_in + n2;
    
    %% --- Receiver 1: SISO (Single Input Single Output) ---
    % Cân bằng kênh (Zero Forcing / Phase correction)
    % y_hat = y1 ./ h1; 
    % Tuy nhiên để tránh chia cho 0 và tối ưu cho BPSK, ta dùng nhân liên hợp:
    y_detect_SISO = y1 .* conj(h1); 
    
    % Quyết định cứng (Hard Decision)
    dec_SISO = real(y_detect_SISO) > 0; % Logic: >0 là bit 1, <0 là bit 0
    dec_SISO = double(dec_SISO); % Chuyển về dạng số 0/1 để so sánh
    
    % Tính BER SISO
    err_SISO = sum(dec_SISO ~= x);
    BER_SISO(i) = err_SISO / N;
    
    %% --- Receiver 2: SIMO MRC (Maximal Ratio Combining) ---
    % Công thức MRC: r = y1*h1' + y2*h2'
    y_comb = y1 .* conj(h1) + y2 .* conj(h2);
    
    % Quyết định cứng
    dec_MRC = real(y_comb) > 0;
    dec_MRC = double(dec_MRC);
    
    % Tính BER MRC
    err_MRC = sum(dec_MRC ~= x);
    BER_SIMO_MRC(i) = err_MRC / N;
    
    fprintf('SNR: %d dB | BER SISO: %e | BER MRC: %e\n', SNR_dB(i), BER_SISO(i), BER_SIMO_MRC(i));
end

%% 3. Tính đường lý thuyết (Theoretical)
BER_Theor_AWGN = 0.5 * erfc(sqrt(SNR_lin));      % Lý thuyết AWGN
BER_Theor_Rayleigh = 0.5 * (1 - sqrt(SNR_lin ./ (1 + SNR_lin))); % Lý thuyết Rayleigh 1 đường

%% 4. Vẽ đồ thị
figure;
% Đường lý thuyết AWGN (Tốt nhất có thể đạt được)
semilogy(SNR_dB, BER_Theor_AWGN, 'k--', 'LineWidth', 1.5); hold on;

% Kết quả mô phỏng
semilogy(SNR_dB, BER_SISO, 'b-o', 'LineWidth', 1.5);
semilogy(SNR_dB, BER_SIMO_MRC, 'r-^', 'LineWidth', 1.5);

grid on;
axis([-10 30 1e-5 1]);
legend('Theoretical AWGN', 'Simulated SISO (Rayleigh)', 'Simulated SIMO MRC (1x2)');
xlabel('SNR (dB)');
ylabel('Bit Error Rate (BER)');
title('Performance of BPSK in Flat Fading (SISO vs MRC)');