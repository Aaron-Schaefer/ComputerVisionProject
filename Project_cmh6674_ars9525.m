function Project_cmh6674_ars9525(fn_in)

  if nargin < 1 % if no input file loop through directory
      file_list = dir('*.jpeg'); 
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
  [L, N] = bwlabel(im);

  card_count = 0;

  %get each card
  for region = 1:N
    %get each card
    [r,c] = find(L==region);
    rc = [r,c];
    
    % surround each card with a bounding box
    min_r = min(r);
    max_r = max(r);
    min_c = min(c);
    max_c = max(c);
   

    xs = [min_c, max_c];
    ys = [min_r, max_r];

    length = max_c - min_c;
    height = max_r - min_r;

    is_card_size = length / size(im,1) < 0.3 && height / size(im,2) < 0.3;


    if length > 300 && height > 300 && is_card_size
      
      card_count = card_count + 1;
      im_card = im(min_r-5 : max_r+5, min_c-5 : max_c+5);
      im_card_rgb = rgb_im(min_r-5 : max_r+5, min_c-5 : max_c+5, :);

      % get just the card without the shapes
      im_rectangle = imfill(im_card, 'holes');

      % hough line detection
      BW = edge(im_rectangle,'canny');
      [H,theta,rho] = hough(BW);
      P = houghpeaks(H,4,'threshold',ceil(0.2*max(H(:))));
      lines = houghlines(BW,theta,rho,P,'FillGap',50,'MinLength',75);
        
      %figure();
      %imagesc(im_card_rgb);
      %colormap(gray);
      %hold on;

      % holds equation of lines 
      p_lines = [0,0;
                 0,0;
                 0,0;
                 0,0];

      % for 4 hough lines get their line equations
      for num = 1:4
        xy = [lines(num).point1; lines(num).point2];

        % account for vertical lines
        if xy(1) == xy(2)
            xy(1) = xy(1) + 1;
        end
        
        % get equation of the line
        p = polyfit(xy(:,1), xy(:,2), 1);
        p_lines(num, :) = p;

        %x1 = linspace(1, length);
        %y1 = polyval(p, x1);
        %plot(x1,y1,'LineWidth',2,'Color','red')

      end

      % sort into horizontal and vertical edges
      horizontal_lines = p_lines(abs(p_lines(:,1)) < 1, : );
      vertical_lines = p_lines(abs(p_lines(:,1)) >= 1, : );

      [y_lim, x_lim] = size(im_rectangle);

      % do calculations only if two horizontal edges and two vertical are
      % found
      if size(horizontal_lines, 1) == 2 && size(vertical_lines, 1) == 2
        
        corners = zeros(4,2);
        for v = 1:2
          for h = 1:2
              vert = vertical_lines(v, :);
              horz = horizontal_lines(h, :);
              
              [x_val, y_val] = point_intersect(vert,horz);

              % limit cordinate to edges of image
              if x_val < 1
                  x_val = 1;
              end
              if x_val > x_lim
                  x_val = x_lim -1;
              end
              if y_val < 1
                  y_val = 1;
              end
              if y_val > y_lim
                  y_val = y_lim-1;
              end

              % corners matrix goes [top-right, top-left, bottom-right,
              % bottom-left]
              if x_val < x_lim / 2 && y_val < y_lim / 2 % top-right
                % plot(x_val, y_val, '.', "Color","red", "MarkerSize",20);
                corners(1, :) = [x_val, y_val];
              elseif x_val > x_lim / 2 && y_val < y_lim / 2 % top left
                % plot(x_val, y_val, '.', "Color","yellow", "MarkerSize",20);
                corners(2, :) = [x_val, y_val];
              elseif x_val < x_lim / 2 && y_val > y_lim / 2 % bottom right
                % plot(x_val, y_val, '.', "Color","cyan", "MarkerSize",20);
                corners(3, :) = [x_val, y_val];
              else % bottom left
                % plot(x_val, y_val, '.', "Color","green", "MarkerSize",20);
                corners(4, :) = [x_val, y_val];
              end
          end
        end

        % do affine tranformation      
        new_points = [1,1; x_lim, 1; 1, y_lim; x_lim, y_lim];
        tform = fitgeotrans(corners, new_points, 'affine');
        new_im = imwarp(im_card_rgb, tform, 'OutputView',imref2d(size(im_card_rgb)));
        new_im = imrotate(new_im,90);
        %figure();
        %imagesc(new_im);


      end
    
      color = card_color(im_card_rgb);
      %shape = card_shape(color, new_im);
      %shape = erase(shape, '.jpg');
      % plot rectangle around card
      hold on;
      plot(xs([ 1 1 2 2 1]), ys([1 2 2 1 1 ]), color, 'LineWidth', 4 );
      %text(xs(1), ys(1), sprintf('%s %s', color, shape), 'Color', 'white', 'FontSize', 6, 'Interpreter', 'none', 'BackgroundColor', 'Black');
      %disp(shape);
    end
  end
  hold off;
  total = ['number of cards =', num2str(card_count)];
  disp(total);
end

function [x0, y0] = point_intersect(p1, p2)
    % get point of intersection between two lines
    x0 = (p2(2) - p1(2) )/(p1(1) - p2(1));
    y0 = p1(1)*x0 + p1(2);

end

function shape=card_shape(color, im)
  % Loop through all images in db folder and use normxcorr2 to find the most similar card
  shape = 'unknown';

  % get all images in db folder of matching color
  db_folder = 'db/*.png';
  switch color
    case 'r-'
      db_folder = 'db/red/*.jpg';
    case 'b-'
      db_folder = 'db/blue/*.jpg';
    case 'g-'
      db_folder = 'db/green/*.jpg';
  end
  file_list = dir(db_folder);
  
  current_best = intmin;

  % loop through all images in db folder
  for counter = 1 : length( file_list )
    fn = file_list(counter);
    fullpath = fullfile(fn.folder, fn.name);
    im_db = im2double(imread(fullpath));

    % resize im_db to be the same size as im
    % TODO Change this resize so it maintaing aspect ratio
    im_db = imresize(im_db, [round(size(im,1) * 0.99), round(size(im,2) * 0.99)]);

    corr = normxcorr2(im2gray(im_db), im2gray(im));
    sm = max(corr(:));

    if sm > current_best
      current_best = sm;
      shape = fn.name;
    end
    %[max_corr, imax] = max(abs(corr(:)));
    % if max_corr > 0.9
    %   shape = fn.name;
    %   break;
    % end
  end
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