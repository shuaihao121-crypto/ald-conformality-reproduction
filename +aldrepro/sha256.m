function digest_text = sha256(bytes,force_matlab)
%SHA256 SHA-256 of uint8 bytes, with a portable base-MATLAB implementation.
%   The optional FORCE_MATLAB=true exercises the no-JVM code in smoke checks.
%   Addition uses uint64 intermediates because MATLAB uint32 addition saturates.
if nargin<2, force_matlab = false; end
validateattributes(bytes,{'uint8'},{});
if ~isempty(bytes) && ~isvector(bytes)
    error('aldrepro:HashInput','SHA256 input must be a uint8 vector.');
end
bytes = bytes(:);
if usejava('jvm') && ~force_matlab
    digest = java.security.MessageDigest.getInstance('SHA-256');
    digest.update(typecast(bytes,'int8'));
    output_bytes = typecast(digest.digest(),'uint8');
    digest_text = lower(reshape(dec2hex(output_bytes,2).',1,[]));
    return
end
initial = uint32(hex2dec(char('6a09e667','bb67ae85','3c6ef372','a54ff53a', ...
    '510e527f','9b05688c','1f83d9ab','5be0cd19')));
constants = uint32(hex2dec(char( ...
    '428a2f98','71374491','b5c0fbcf','e9b5dba5','3956c25b','59f111f1','923f82a4','ab1c5ed5', ...
    'd807aa98','12835b01','243185be','550c7dc3','72be5d74','80deb1fe','9bdc06a7','c19bf174', ...
    'e49b69c1','efbe4786','0fc19dc6','240ca1cc','2de92c6f','4a7484aa','5cb0a9dc','76f988da', ...
    '983e5152','a831c66d','b00327c8','bf597fc7','c6e00bf3','d5a79147','06ca6351','14292967', ...
    '27b70a85','2e1b2138','4d2c6dfc','53380d13','650a7354','766a0abb','81c2c92e','92722c85', ...
    'a2bfe8a1','a81a664b','c24b8b70','c76c51a3','d192e819','d6990624','f40e3585','106aa070', ...
    '19a4c116','1e376c08','2748774c','34b0bcb5','391c0cb3','4ed8aa4a','5b9cca4f','682e6ff3', ...
    '748f82ee','78a5636f','84c87814','8cc70208','90befffa','a4506ceb','bef9a3f7','c67178f2')));
bit_length = uint64(numel(bytes))*uint64(8);
zero_count = mod(56-mod(numel(bytes)+1,64),64);
length_bytes = zeros(8,1,'uint8');
for k = 1:8
    length_bytes(k) = uint8(bitand(bitshift(bit_length,-8*(8-k)),uint64(255)));
end
padded = [bytes; uint8(128); zeros(zero_count,1,'uint8'); length_bytes];
state = initial;
for offset = 0:64:numel(padded)-64
    schedule = zeros(64,1,'uint32');
    for k = 1:16
        j = offset+4*(k-1);
        schedule(k) = bitor(bitor(bitshift(uint32(padded(j+1)),24), ...
            bitshift(uint32(padded(j+2)),16)), ...
            bitor(bitshift(uint32(padded(j+3)),8),uint32(padded(j+4))));
    end
    for k = 17:64
        s0 = bitxor(bitxor(rotate(schedule(k-15),7),rotate(schedule(k-15),18)),bitshift(schedule(k-15),-3));
        s1 = bitxor(bitxor(rotate(schedule(k-2),17),rotate(schedule(k-2),19)),bitshift(schedule(k-2),-10));
        schedule(k) = add32(schedule(k-16),s0,schedule(k-7),s1);
    end
    a=state(1); b=state(2); c=state(3); d=state(4);
    e=state(5); f=state(6); g=state(7); h=state(8);
    for k = 1:64
        s1 = bitxor(bitxor(rotate(e,6),rotate(e,11)),rotate(e,25));
        choice = bitxor(bitand(e,f),bitand(bitcmp(e),g));
        t1 = add32(h,s1,choice,constants(k),schedule(k));
        s0 = bitxor(bitxor(rotate(a,2),rotate(a,13)),rotate(a,22));
        majority = bitxor(bitxor(bitand(a,b),bitand(a,c)),bitand(b,c));
        t2 = add32(s0,majority);
        h=g; g=f; f=e; e=add32(d,t1); d=c; c=b; b=a; a=add32(t1,t2);
    end
    working = [a;b;c;d;e;f;g;h];
    for k = 1:8, state(k) = add32(state(k),working(k)); end
end
digest_text = lower(reshape(dec2hex(state,8).',1,[]));
end

function y = rotate(x,n)
y = bitor(bitshift(x,-n),bitshift(x,32-n));
end

function y = add32(varargin)
total = uint64(0);
for k = 1:nargin, total = total+uint64(varargin{k}); end
y = uint32(bitand(total,uint64(4294967295)));
end
