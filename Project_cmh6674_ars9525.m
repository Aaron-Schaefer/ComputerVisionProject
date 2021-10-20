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
    get_each_card(new_im);

  
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

function get_each_card(im)
  % show image
  figure(1);
  imshow(im);


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

    xs = [min_c, max_c];
    ys = [min_r, max_r];

    length = max_c - min_c;
    height = max_r - min_r;



    is_card_size = length / size(im,1) < 0.2 || height / size(im,2) < 0.2;

    if size(im_card,1) > 300 && size(im_card,2) > 300 && is_card_size
      % plot rectangle around card
      hold on;
      plot(xs([ 1 1 2 2 1]), ys([1 2 2 1 1 ]), 'c-', 'LineWidth', 4 );
    end
  end
  hold off;
end

