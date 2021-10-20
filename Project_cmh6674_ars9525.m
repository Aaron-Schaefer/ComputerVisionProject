function Project_cmh6674_ars9525(fn_in)

  if nargin < 1 % if no input file loop through directory
      file_list = dir('*.jpg'); 
       for counter = 1 : length( file_list )
           fn = file_list(counter);
           find_cards(fn.name);
       end
  else
    find_cards(fn_in);
  end
  
end

function find_cards(fn_in)

    im = im2double(imread(fn_in));
    new_im = preprocess_image(im);
    get_each_card(new_im, im);

  
end

function im = preprocess_image(im)
  % does preprocessing to remove noise and binarizes image

  im = im2gray(im);
  % Convert to gray thresh
  thresh = graythresh(im);
  im = imbinarize(im, thresh + 0.15);

  % Perform opening on the image to remove specs
  se = strel('disk',5);
  im = imopen(im,se);

end

% im is the preprocessed image
% rgb_im is the image in rgb color space
function get_each_card(im, rgb_im)
  % show image
  figure(1);
  imshow(rgb_im);


  % use bwlabel to get regions of the image
  [L, num] = bwlabel(im);

  %get each card
  for i = 1:num
    %get each card
    [r,c] = find(L==i);
    
    % surround each card with a bounding box
    min_r = min(r);
    max_r = max(r);
    min_c = min(c);
    max_c = max(c);
    im_card = im(min_r : max_r, min_c : max_c);
    im_card_rgb = rgb_im(min_r : max_r, min_c : max_c, :);

    xs = [min_c, max_c];
    ys = [min_r, max_r];

    length = max_c - min_c;
    height = max_r - min_r;



    is_card_size = length / size(im,1) < 0.2 || height / size(im,2) < 0.2;

    if size(im_card,1) > 300 && size(im_card,2) > 300 && is_card_size
      color = card_color(im_card_rgb);
      % plot rectangle around card
      hold on;
      plot(xs([ 1 1 2 2 1]), ys([1 2 2 1 1 ]), color, 'LineWidth', 4 );
    end
  end
  hold off;
end


function color=card_color(im)
  % Red
  [ rx, ry ] = histo_proj((im(:,:,1) + im(:,:,2) - 2*im(:,:,3))/3);
  % Green
  [ gx, gy ] = histo_proj((2*im(:,:,2) - im(:,:,1) - im(:,:,3))/3);
  % Blue
  [ bx, by ] = histo_proj((2*im(:,:,3) - im(:,:,1) - im(:,:,2))/3);

  % Detect which color it is by the most centered coordinates
  rxc = abs(rx - size(im,2)/2);
  ryc = abs(ry - size(im,1)/2);
  gxc = abs(gx - size(im,2)/2);
  gyc = abs(gy - size(im,1)/2);
  bxc = abs(bx - size(im,2)/2);
  byc = abs(by - size(im,1)/2);

  [~, idx] = min([rxc, gxc, bxc, ryc, gyc, byc]);

  switch idx
    case 1
      color = 'r-';
    case 2
      color = 'g-';
    case 3
      color = 'b-';
    case 4
      color = 'r-';
    case 5
      color = 'g-';
    case 6
      color = 'b-';
  end

end

function [ bb, aa ] = histo_proj(im_clr)
  im_clr  = imfilter( im_clr, fspecial('Gauss', 45, 9), 'same', 'repl' );
  
  sum_of_cols = sum( im_clr, 1 );
  sum_of_rows = sum( im_clr, 2 );

  sum_of_rows = (sum_of_rows - min(sum_of_rows)) / ( max(sum_of_rows) - min(sum_of_rows) );
  sum_of_cols = (sum_of_cols - min(sum_of_cols)) / ( max(sum_of_cols) - min(sum_of_cols) );

  local_probabilities = sum_of_rows * sum_of_cols;
  
  [ mmax, mmidx ] = max( local_probabilities(:) );
  [aa,bb] = ind2sub( size(local_probabilities), mmidx );
end