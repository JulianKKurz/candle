classdef GrayVideoAnalyzer
    methods(Static)
        function threshold_level = calculate_optimal_threshold(video)
            % Funktion zum Berechnen und Rückgabe des idealen Threshold-Werts für das Bild mit den hellsten Pixeln aus einem Video.
            %
            % Eingabe:
            % video - Struktur mit Graustufen-Frames.
            %a
            % Ausgabe:
            % threshold_level - idealer Threshold-Wert (0 bis 255).

            % Initialisieren des Bildes mit den maximalen Pixelwerten.
            [height, width] = size(video(1).gray);
            max_image = zeros(height, width);
            num_frames = length(video);

            % Video Frame für Frame verarbeiten.
            for frame_idx = 1:num_frames
                img_gray = video(frame_idx).gray;

                % Aktualisieren des Bildes mit den maximalen Pixelwerten.
                max_image = max(max_image, double(img_gray));
            end

            % Berechnung des optimalen Threshold-Werts mit dem Otsu-Algorithmus.
            max_image_uint8 = uint8(max_image); % Umwandlung in uint8 für den Otsu-Algorithmus.
            threshold_level = graythresh(max_image_uint8) * 255; % Otsu-Algorithmus liefert einen Wert zwischen 0 und 1, Umwandlung in 0-255.
        end

        % Funktion zur Radiusberechnung basierend auf der Helligkeit
        function radius = calculate_radius(scaled_video, brightest_coords, video_height, video_width, radius_tolerance_percent)
            % Berechne die Dimensionen des Videos (Höhe und Breite)
            borders = [video_height, video_width];

            % Initialisiere eine Liste zur Speicherung der Werte
            values = [];

            % Berechne Durchschnittswerte für jeden Radius von 1 bis zur Hälfte der kleinsten Dimension
            for radius = 1:round(min(borders)/2)
                % Berechne den Durchschnittswert im quadratischen Bereich um die hellsten Koordinaten
                average = GrayVideoAnalyzer.get_square_average(scaled_video, brightest_coords, radius);
                values = [values, average];
            end

            % Berechne die prozentualen Differenzen zwischen den Werten
            percent_values = abs(diff(values));
            percent_values = percent_values / max(percent_values);

            % Wenn eine Differenz kleiner als die Toleranz ist, wähle diesen Radius
            if any(percent_values < round(radius_tolerance_percent/100))
                radius = find(percent_values < radius_tolerance_percent/100, 1);
            else
                % Andernfalls wähle den kleinsten Differenzwert
                radius = find(percent_values == min(percent_values), 1);
            end

            % Gib den gefundenen Radius aus
            disp("radius");
            disp(radius);
        end

        function avg_values = compute_segment_averages(segmented_video)
            % Funktion zum Berechnen des Durchschnittswerts für jedes Segment und jedes Frame
            %
            % Eingabe:
            % segmented_video - Struktur mit den Segmenten pro Frame
            %
            % Ausgabe:
            % avg_values - Durchschnittswerte des ersten Segments

            num_frames = length(segmented_video);
            avg_values = zeros(1, num_frames);

            for frame_idx = 1:num_frames
                % Extrahiere das Segment des aktuellen Frames
                frame = segmented_video(frame_idx).gray;

                % Berechne den Durchschnittswert des Segments
                avg_values(frame_idx) = mean(frame(:));
            end
        end

        function total_areas = count_areas(threshold)
            % Funktion zum Zählen der zusammenhängenden Bereiche in jedem Frame eines binarisierten Videos
            %
            % Eingabe:
            % threshold - Struktur mit binarisierten Frames
            %
            % Ausgabe:
            % total_areas_avg - Durchschnitt der zusammenhängenden Bereiche über alle Frames

            % Initialisieren der Summe der zusammenhängenden Bereiche
            total_areas = 0;

            % Video Frame für Frame verarbeiten
            for frame_idx = 1:length(threshold)
                binary_image = threshold(frame_idx).gray;

                % Ermitteln der zusammenhängenden Bereiche mit 'bwlabel'
                cc = bwconncomp(binary_image);

                % Anzahl der zusammenhängenden Bereiche hinzufügen
                total_areas = [total_areas cc.NumObjects];
            end
        end

        function quantity = count_pixels(gray_video, level)
            % Funktion zur Zählung der Pixel, die einen bestimmten Grauwert oder höher haben
            %
            % Eingabe:
            % gray_video - 1xN struct array von Graustufenbildern, jedes mit dem Feld 'gray'
            % level - Der Grauwert (zwischen 0 und 255), ab dem die Pixel gezählt werden
            %
            % Ausgabe:
            % quantity - Array mit der Anzahl der Pixel, die den Wert 'level' oder höher
            %            haben für jeden Frame

            % Anzahl der Frames im Video
            num_frames = length(gray_video);

            % Initialisierung des Arrays zur Speicherung der Anzahl der Pixel pro Frame
            quantity = zeros(1, num_frames);

            % Loop über alle Frames im Video
            for i = 1:num_frames
                % Extrahiere das Graustufenbild des aktuellen Frames
                frame = gray_video(i).gray;

                % Finde die Pixel, deren Wert den angegebenen Level erreicht oder überschreitet
                matching_pixels = frame >= level;

                % Speichere die Anzahl der passenden Pixel für den aktuellen Frame im Array
                quantity(i) = sum(matching_pixels(:));
            end
        end

        function average = get_average(gray_video)
            % Funktion zur Berechnung des Durchschnittswerts aller Pixel in einem Graustufenvideo
            %
            % Eingabe:
            % gray_video - 1xN struct array von Graustufenbildern, jedes mit dem Feld 'gray'
            %
            % Ausgabe:
            % average - Durchschnittswert aller Pixel (skalare Größe)

            % Anzahl der Frames im Video
            num_frames = length(gray_video);

            % Initialisierung der Gesamtsumme und der Gesamtanzahl der Pixel
            total_sum = 0;
            total_pixels = 0;

            % Loop über alle Frames im Video
            for i = 1:num_frames
                % Extrahiere das Graustufenbild des aktuellen Frames
                frame = gray_video(i).gray;

                % Addiere die Summe aller Pixelwerte des aktuellen Frames zur Gesamtsumme
                total_sum = total_sum + sum(frame(:));

                % Addiere die Anzahl der Pixel des aktuellen Frames zur Gesamtpixelanzahl
                total_pixels = total_pixels + numel(frame);
            end

            % Berechnung des Durchschnittswerts
            average = total_sum / total_pixels;
        end

        function average_coords = get_average_coord(video)
            % Funktion zum Berechnen der durchschnittlichen Koordinaten aller
            % Pixel mit dem Wert 255 in jedem Frame eines Videos
            %
            % Eingabe:
            % video - Struktur mit binären Frames (Pixelwerte 0 oder 255)
            %
            % Ausgabe:
            % average_coords - Nx2 Matrix mit den durchschnittlichen Zeilen- und
            %                  Spaltenkoordinaten der Pixel mit Wert 255 in jedem Frame.
            %                  N ist die Anzahl der Frames.

            if isempty(video)
                error('Das Eingabevideo darf nicht leer sein.');
            end

            % Initialisieren der Ausgabe: eine Nx2 Matrix für die Koordinaten
            average_coords = zeros(length(video), 2);

            % Video Frame für Frame verarbeiten
            for frame_idx = 1:length(video)
                img_binary = video(frame_idx).gray;

                if isempty(img_binary) || size(img_binary, 1) == 0 || size(img_binary, 2) == 0
                    % Falls das Bild leer oder ungültig ist, weiter zur nächsten Iteration
                    average_coords(frame_idx, :) = [NaN, NaN];
                    continue;
                end

                % Finden aller Positionen der Pixel mit Wert 255
                [rows, cols] = find(img_binary == 255);

                if isempty(rows)
                    % Falls keine hellen Pixel (255) gefunden werden, NaN eintragen
                    average_coords(frame_idx, :) = [NaN, NaN];
                else
                    % Berechnen der durchschnittlichen Zeilen- und Spaltenkoordinaten
                    avg_row = mean(rows);
                    avg_col = mean(cols);

                    % Speichern der durchschnittlichen Koordinaten
                    average_coords(frame_idx, :) = [avg_row, avg_col];
                end
            end
        end

        function brightest_coords = get_brightest_coord(video)
            % Funktion zum Finden der Koordinaten des hellsten Pixels in jedem Frame eines Videos
            % und zum Überprüfen, ob auf der Strecke zwischen den hellsten Punkten schwarze Pixel liegen.
            % Falls mehrere Maximalwerte existieren, wird der Punkt aus der Gruppe mit den meisten Punkten gewählt.
            % Die Ergebnisse des gesamten Funktionsaufrufs werden am Ende zusammengefasst.
            %
            % Eingabe:
            % video - Struktur mit Graustufen-Frames
            %
            % Ausgabe:
            % brightest_coords - Nx2 Matrix mit den Zeilen- und Spaltenkoordinaten
            %                    des hellsten Pixels in jedem Frame. N ist die Anzahl der Frames.

            if isempty(video)
                error('Das Eingabevideo darf nicht leer sein.');
            end

            num_frames = length(video);
            % Initialisieren der Ausgabe: eine Nx2 Matrix für die Koordinaten
            brightest_coords = zeros(num_frames, 2);

            % Zähler für Mehrdeutigkeiten und schwarze Pixel
            ambiguous_frames_count = 0;
            black_pixel_count = 0;

            % Initialisieren eines Zellarrays, um alle maximalen Punkte zu speichern
            all_max_points = cell(num_frames, 1);

            % Erster Durchlauf: Sammeln aller maximalen Punkte
            for frame_idx = 1:num_frames
                img_gray = video(frame_idx).gray;

                if isempty(img_gray) || size(img_gray, 1) == 0 || size(img_gray, 2) == 0
                    % Falls das Bild leer oder ungültig ist
                    brightest_coords(frame_idx, :) = [NaN, NaN];
                    continue;
                end

                % Maximalen Helligkeitswert finden
                max_brightness = max(img_gray(:));

                % Finden aller Positionen mit dem Maximalwert
                [max_rows, max_cols] = find(img_gray == max_brightness);

                % Speichern der Positionen in der Zellarray
                all_max_points{frame_idx} = [max_rows, max_cols];

                % Überprüfen auf Mehrdeutigkeiten
                if length(max_rows) > 1
                    ambiguous_frames_count = ambiguous_frames_count + 1;
                end
            end

            % Alle maximalen Punkte zusammenführen
            all_max_points_concat = cell2mat(all_max_points);

            % Clustering der maximalen Punkte in zwei Gruppen
            num_clusters = 2;
            [cluster_idx, ~] = kmeans(all_max_points_concat, num_clusters);

            % Anzahl der Punkte in jedem Cluster zählen
            cluster_counts = histcounts(cluster_idx, num_clusters);

            % Cluster mit den meisten Punkten bestimmen
            [~, majority_cluster] = max(cluster_counts);

            % Zweiter Durchlauf: Auswahl der Punkte aus dem Mehrheitscluster
            point_counter = 1;
            for frame_idx = 1:num_frames
                max_points = all_max_points{frame_idx};

                if isempty(max_points)
                    brightest_coords(frame_idx, :) = [NaN, NaN];
                    continue;
                end

                % Indizes der aktuellen Punkte im Gesamtarray
                num_points_in_frame = size(max_points,1);
                indices = point_counter:(point_counter+num_points_in_frame-1);

                % Clusterzugehörigkeit der Punkte im aktuellen Frame
                clusters_in_frame = cluster_idx(indices);

                % Punkte aus dem Mehrheitscluster auswählen
                points_in_majority_cluster = max_points(clusters_in_frame == majority_cluster, :);

                if isempty(points_in_majority_cluster)
                    % Falls kein Punkt aus dem Mehrheitscluster vorhanden ist, ersten Punkt wählen
                    brightest_coords(frame_idx, :) = max_points(1,:);
                else
                    % Wenn mehrere Punkte vorhanden sind, den nächsten zum vorherigen auswählen
                    if frame_idx > 1 && ~any(isnan(brightest_coords(frame_idx-1, :)))
                        prev_row = brightest_coords(frame_idx-1, 1);
                        prev_col = brightest_coords(frame_idx-1, 2);

                        distances = sqrt((points_in_majority_cluster(:,1) - prev_row).^2 + ...
                            (points_in_majority_cluster(:,2) - prev_col).^2);
                        [~, min_idx] = min(distances);

                        brightest_coords(frame_idx, :) = points_in_majority_cluster(min_idx, :);
                    else
                        % Im ersten Frame einfach den ersten Punkt wählen
                        brightest_coords(frame_idx, :) = points_in_majority_cluster(1,:);
                    end
                end

                % Überprüfung auf schwarze Pixel zwischen den Punkten
                if frame_idx > 1 && ~any(isnan(brightest_coords(frame_idx-1, :))) && ~any(isnan(brightest_coords(frame_idx, :)))
                    prev_row = brightest_coords(frame_idx-1, 1);
                    prev_col = brightest_coords(frame_idx-1, 2);
                    curr_row = brightest_coords(frame_idx, 1);
                    curr_col = brightest_coords(frame_idx, 2);

                    line_pixels = GrayVideoAnalyzer.bresenham_line(prev_row, prev_col, curr_row, curr_col);

                    % Überprüfen der Helligkeit auf schwarze Pixel
                    img_gray = video(frame_idx).gray;
                    for i = 1:size(line_pixels, 1)
                        row = line_pixels(i, 1);
                        col = line_pixels(i, 2);
                        if img_gray(row, col) == 0
                            black_pixel_count = black_pixel_count + 1;
                            fprintf('Schwarzes Pixel bei Frame %d auf der Linie zwischen (%d, %d) und (%d, %d)\n', ...
                                frame_idx, prev_row, prev_col, curr_row, curr_col);
                        end
                    end
                end

                % Aktualisieren des Zählers
                point_counter = point_counter + num_points_in_frame;
            end

            % Zusammenfassung der Ergebnisse
            fprintf('Zusammenfassung des Funktionsaufrufs:\n');
            fprintf('- Anzahl der Frames mit mehreren Maximalwerten: %d\n', ambiguous_frames_count);
            fprintf('- Anzahl der gefundenen schwarzen Pixel auf den Linien: %d\n', black_pixel_count);
            fprintf('- Gesamtanzahl der Frames im Video: %d\n', num_frames);
        end

        function line_pixels = bresenham_line(x1, y1, x2, y2)
            % Bresenham-Algorithmus zur Berechnung aller Pixel auf der Linie zwischen (x1, y1) und (x2, y2)
            % Ausgabe ist eine Nx2-Matrix mit Zeilen und Spalten aller Pixel auf der Linie

            dx = abs(x2 - x1);
            dy = abs(y2 - y1);
            sx = sign(x2 - x1);
            sy = sign(y2 - y1);

            x = x1;
            y = y1;

            if dy <= dx
                % Linie ist mehr horizontal als vertikal
                err = dx / 2;
                line_pixels = zeros(dx + 1, 2);
                for ix = 0:dx
                    line_pixels(ix + 1, :) = [x, y];
                    x = x + sx;
                    err = err - dy;
                    if err < 0
                        y = y + sy;
                        err = err + dx;
                    end
                end
            else
                % Linie ist mehr vertikal als horizontal
                err = dy / 2;
                line_pixels = zeros(dy + 1, 2);
                for iy = 0:dy
                    line_pixels(iy + 1, :) = [x, y];
                    y = y + sy;
                    err = err - dx;
                    if err < 0
                        x = x + sx;
                        err = err + dy;
                    end
                end
            end
        end

        function average = get_square_average(gray_video, brightest_coords, radius)
            % Funktion zur Berechnung des Durchschnittswerts der Pixel innerhalb quadratischer
            % Bereiche in einem Graustufen-Video.
            %
            % Eingabe:
            % gray_video      - Struktur mit Graustufen-Frames (0-255)
            % brightest_coords - Nx2 Matrix mit Koordinaten [max_row, max_col] für jeden Frame
            % radius          - Radius des quadratischen Ausschneidebereichs
            %
            % Ausgabe:
            % average         - Durchschnittswert der Pixel innerhalb der quadratischen Bereiche

            % Fehlerüberprüfungen
            if nargin ~= 3
                error('Die Funktion erfordert drei Eingabeargumente: gray_video, brightest_coords und radius.');
            end

            if isempty(gray_video)
                error('Das gray_video darf nicht leer sein.');
            end

            if isempty(brightest_coords)
                error('Die brightest_coords dürfen nicht leer sein.');
            end

            if ~isnumeric(radius) || ~isscalar(radius) || radius < 0
                error('radius muss ein positiver Skalarwert sein.');
            end

            num_frames_gray = length(gray_video);
            [num_frames_coord, num_cols] = size(brightest_coords);

            if num_frames_gray ~= num_frames_coord
                error('Die Anzahl der Frames in gray_video muss mit der Anzahl der Koordinaten übereinstimmen.');
            end

            if num_cols ~= 2
                error('brightest_coords muss eine Nx2 Matrix sein, wobei jede Zeile [max_row, max_col] enthält.');
            end

            % Initialisierung der Gesamtsumme und der Gesamtanzahl der Pixel
            total_sum = 0;
            total_pixels = 0;

            for frame_idx = 1:num_frames_gray
                gray_frame = gray_video(frame_idx).gray;

                if isempty(gray_frame)
                    % Überspringe leere Frames
                    continue;
                end

                % Extrahiere die Koordinaten für das aktuelle Frame
                center_row = brightest_coords(frame_idx, 1);
                center_col = brightest_coords(frame_idx, 2);

                % Überprüfen, ob coord innerhalb der Bildgrenzen liegt
                [num_rows, num_cols_frame] = size(gray_frame);

                if center_row < 1 || center_row > num_rows || center_col < 1 || center_col > num_cols_frame
                    error('Frame %d: Koordinaten [%d, %d] liegen außerhalb der Bildgrenzen.', ...
                        frame_idx, center_row, center_col);
                end

                % Definieren der Grenzen des quadratischen Bereichs
                row_start = max(center_row - radius, 1);
                row_end   = min(center_row + radius, num_rows);
                col_start = max(center_col - radius, 1);
                col_end   = min(center_col + radius, num_cols_frame);

                % Extrahieren des quadratischen Bereichs
                square_region = gray_frame(row_start:row_end, col_start:col_end);

                % Berechnung der Summe und Anzahl der Pixel im quadratischen Bereich
                total_sum = total_sum + sum(square_region(:));
                total_pixels = total_pixels + numel(square_region);
            end

            % Berechnung des Durchschnittswerts
            if total_pixels == 0
                warning('Keine Pixel zum Berechnen des Durchschnitts gefunden.');
                average = NaN;
            else
                average = total_sum / total_pixels;
            end
        end

        %% Funktion zur Parameteroptimierung
        function [optimal_window, optimal_blur] = optimize_parameters(scaled_video)
            % Optimierung der Fenstergröße für den gleitenden Durchschnitt
            max_window = 30;
            window_values = zeros(1, max_window);
            for window = 1:max_window
                moving_average_video = GrayVideoConverter.apply_moving_average(scaled_video, window);
                blur_video = GrayVideoConverter.apply_blur(moving_average_video, 1);
                threshold_video = GrayVideoConverter.apply_threshold(blur_video);
                total_areas = GrayVideoAnalyzer.count_areas(threshold_video);
                window_values(window) = mean(abs(diff(total_areas)));
            end
            [~, optimal_window] = min(window_values);
            disp("Optimal window:");
            disp(optimal_window);

            % Optimierung des Blur-Faktors
            max_blur = 10;
            blur_values = zeros(1, max_blur);
            moving_average_video = GrayVideoConverter.apply_moving_average(scaled_video, optimal_window);
            for blur = 1:max_blur
                blur_video = GrayVideoConverter.apply_blur(moving_average_video, blur);
                threshold_video = GrayVideoConverter.apply_threshold(blur_video);
                total_areas = GrayVideoAnalyzer.count_areas(threshold_video);
                blur_values(blur) = mean(abs(diff(total_areas)));
            end
            [~, optimal_blur] = min(blur_values);
            disp("Optimal blur:");
            disp(optimal_blur);
        end

        function max_img = apply_gray_max_image(gray_video)
            % Berechnet das maximale Bild aus allen Frames eines Graustufen-Videos
            % Eingabe:
            %   gray_video – struct mit Feld .gray
            % Ausgabe:
            %   max_img    – Pixelweises Maximum über alle Frames als 2D-Matrix

            num_frames = numel(gray_video);
            [h, w] = size(gray_video(1).gray);
            max_img = zeros(h, w, 'double');

            for i = 1:num_frames
                current = double(gray_video(i).gray);
                max_img = max(max_img, current);
            end

            max_img = uint8(max_img);
        end
    end
end