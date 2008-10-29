load lambda_m
load a_m
load u1
load u2
load u3
load u4
load u5
load u6
load u7
load u8
load u9
load u10
load u11
load u12
load u13

u = zeros(13, 195);
u(1,1:size(u1,1)) = u1(:,2);
u(2,1:size(u2,1)) = u2(:,2);
u(3,1:size(u3,1)) = u3(:,2);
u(4,1:size(u4,1)) = u4(:,2);
u(5,1:size(u5,1)) = u5(:,2);
u(6,1:size(u6,1)) = u6(:,2);
u(7,1:size(u7,1)) = u7(:,2);
u(8,1:size(u8,1)) = u8(:,2);
u(9,1:size(u9,1)) = u9(:,2);
u(10,1:size(u10,1)) = u10(:,2);
u(11,1:size(u11,1)) = u11(:,2);
u(12,1:size(u12,1)) = u12(:,2);
u(13,1:size(u13,1)) = u13(:,2);

logu = zeros(size(u));
small = (abs(u)<1e-5);
logu(~small) = log(abs(log(1+u(~small))));
logu(small & u ~= 0) = log(abs(u(small & u ~= 0)));

figure(1)
clf
plot(a_m(:,1), log(a_m(:,2)))
hold on
plot(a_m(:,1), log(a_m(:,2)), 'o')
hold off
grid on
axis([1 13 -0.65 -0.25])
print -depsc loga.eps

figure(2)
clf
plot(lambda_m(:,1), log(lambda_m(:,2)))
hold on
plot(lambda_m(:,1), log(lambda_m(:,2)), 'o')
hold off
grid on
axis([1 13 0 15])
print -depsc loglambda.eps


figure(3)
clf
plot(logu(1,1:size(u1,1)), 'b')
hold on
plot(logu(2,1:size(u2,1)), 'c')
plot(logu(3,1:size(u3,1)), 'g')
plot(logu(4,1:size(u4,1)), 'y')
plot(logu(5,1:size(u5,1)), 'm')
plot(logu(6,1:size(u6,1)), 'r')
plot(logu(7,1:size(u7,1)), 'k')
plot(logu(8,1:size(u8,1)), 'b')
plot(logu(9,1:size(u9,1)), 'c')
plot(logu(10,1:size(u10,1)), 'g')
plot(logu(11,1:size(u11,1)), 'y')
plot(logu(12,1:size(u12,1)), 'm')
plot(logu(13,1:size(u13,1)), 'r')
hold off
grid on
axis([1 195 -450 0])
print -depsc logr1.eps

figure(4)
clf
hold on
for k = 10:10:190
    I = find(u(:,k) ~= 0);
    plot(I, logu(I,k));
    plot(I, logu(I,k), 'o');
end
hold off
grid on
axis([1 13 -450 0])
print -depsc logr2.eps

figure(5)
clf
hold on
colors = 'bcgymrk';
for k = -3:3
    v = diag(logu, k);
    I = find(v ~= 0);
    plot(I, v(I), colors(mod(k,7)+1));
end
legend('d=-3','d=-2','d=-1','d= 0','d= 1','d= 2','d= 3')
for k = -3:3
    v = diag(logu, k);
    I = find(v ~= 0);
    plot(I, v(I), [colors(mod(k,7)+1) 'o']);
end
hold off
grid on
axis([1 13 -37 0])
set(gca,'xtick',1:13)
print -depsc logrdiag.eps

L = zeros(200,200);
for k = 1:13
    data = textread(['L' num2str(k)], '%s');
    for m = 3:2:length(data)
        n = str2num(data{m});
        l = log(str2num(['.' data{m+1}])) + log(10) * length(data{m+1});
        L(k,n) = l;
        L(n,k) = l;
    end
end

L0 = log(2.97573419204335725);
B0 = log(0.96553505933836965);
A0 = log(0.850639925845833);

[m,n] = ndgrid(1:200,1:200);
q = L - L0*m.*n - B0*(m+n) - A0;
