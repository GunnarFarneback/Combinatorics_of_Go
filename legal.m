function [num, num8] = legal(bsize, bsize2)

% 0 empty
% 1 black 
% 2 white
% 3 border

% find a column top down (used both in the left and as new columns when progressing)
A=ones(3^bsize,1);
U=zeros(3^bsize,bsize);
for a=1:3^bsize,
  temp = a-1; 
  old = 3;
  liberty = 0; % liberty available from the top
  u = zeros(1,bsize);
  for j=1:bsize,
    new = mod(temp,3);
    temp = floor(temp/3);
    % old group gets the needed liberty from the bottom?
    if (and(and(new == 0, j>1), liberty==0))
      u(find(u==u(j-1))) = 0;
    end;
    if (or(and(old==1,new==2), and(old==2,new==1))),
      liberty = 0; 
    end;
    if (or(old==0, new==0)) 
      liberty = 1;
    end;
    % mark stones without liberties to belong to a group
    if (liberty==0)
      if (old~=new) 
        u(j)=j;
      else
        u(j)=u(j-1);
      end;
    end;
    old = new;
  end;
  U(a,:)=u;
end;
newstates = find(A);
nnew = size(newstates,1);
newU = U(newstates,:);

fprintf('Column: 1, States: %d, Positions: %d\n',nnew,nnew);

% going columnwise from left to right
olds = newstates;
oldU = newU;
oldnum = ones(size(olds));
oldnum8 = oldnum;
for k=2:bsize2,
  states = [];
  U = [];
  num = [];
  num8 = [];
  for n=1:nnew;
    temp = newstates(n)-1; 
    for j=1:bsize,
      ne(j)=mod(temp,3);
      temp = floor(temp/3);
    end;
    first = size(U,1)+1;
    for o=1:length(olds),
      temp = olds(o)-1;
      u = newU(n,:);
      oldu = oldU(o,:);
      for j=1:bsize,
        ol(j)=mod(temp,3);
        temp = floor(temp/3);
        % new stones get a liberty in the left (unify with group 0)
        if and(ne(j)>0, ol(j)==0)
          u(find(u==u(j)))=0;
        end;
        % old stones get a liberty in the right (unify with group 0)
        if and(ol(j)>0, ne(j)==0),
          oldu(find(oldu==oldu(j)))=0;
        end;
        % horizontal connections
        unif(j) = and(ol(j)>0, ol(j)==ne(j));
      end;
      % check if all old groups got liberties or connected to new groups
      ok = 1;
      for j=1:bsize,
        if (oldu(j)>0),
          ok = and(ok, max(unif(find(oldu==oldu(j)))));
        end;
      end;
      if (ok==0),
        continue;
      end;
      % groups separate in the column but connected through the left
      for j=1:bsize,
	if (u(j)==0)
          continue;
        end;
	leftgroups = oldu(find(and(unif, u==u(j))));
        if (min(leftgroups)==0)
          u(find(u==u(j))) = 0; % got a liberty from a connection to the left
	else
  	  minimum = u(j);
          for jj=1:length(leftgroups),
	    minimum = min(minimum,min(u(find(and(unif, oldu==leftgroups(jj))))));
	  end;
          u(find(u==u(j))) = minimum;
	end;
      end;
      % combining resulting state with another one (if equivalent)
      done = 0;
      for (i=first:size(U,1))
        if (min(u==U(i,:))==1)
          num(i)=num(i)+oldnum(o);
          num8(i)=mod(num8(i)+oldnum8(o),100000000);
          done = 1;
        end;
      end;
      if (done == 1),
        continue; 
      end;
      % adding a new state
      states(end+1) = newstates(n);
      U(end+1,:) = u;
      num(end+1) = oldnum(o);
      num8(end+1) = oldnum8(o);
    end;
  end;
  olds = states;
  oldU = U;
  oldnum = num;
  oldnum8 = num8;
  fprintf('Column: %d, States: %d, Positions: %d\n',k,length(states),sum(num));
end;

% remove positions where groups rely on liberties to the right (edge of the board)
for i=1:size(U,1),
  if (max(U(i,:))>0),
    num(i)=0;
    num8(i)=0;
  end;
end;
% last 8 digits
sum8 = 0;
for i=1:size(U,1),
  sum8 = mod(sum8+num8(i),100000000);
end;

% Results:
fprintf('For %d by %d Go board there are %d legal positions. (last 8 digits: %d)\n',bsize,bsize2,sum(num),sum8);

