classdef GrayVideoConverter
    methods(Static)
        function gray_video = apply_linearized_gray_converter(video)
            % Konvertiert ein RGB-Video in linearisiertes Graustufen-Video (0–255)
            % Verwendet die offizielle sRGB-Dekodierungsformel (IEC 61966-2-1)

            video.CurrentTime = 0;  % Zurückspulen

            gray_video = struct();
            frame_idx = 1;

            while hasFrame(video)
                rgb = im2double(readFrame(video));  % RGB-Werte im Bereich [0, 1]
                rgb_lin = zeros(size(rgb));         % Linearisierte Ausgabe vorbereiten

                % Offizielle sRGB-Dekodierung
                mask = rgb <= 0.04045;
                rgb_lin(mask) = rgb(mask) / 12.92;
                rgb_lin(~mask) = ((rgb(~mask) + 0.055) / 1.055) .^ 2.4;

                % Lineare Grauwertberechnung nach Rec. 709 (ITU / BT.709 / sRGB)
                gray = 0.2126 * rgb_lin(:, :, 1) + ...
                    0.7152 * rgb_lin(:, :, 2) + ...
                    0.0722 * rgb_lin(:, :, 3);

                % In 8-Bit-Bereich skalieren
                gray_video(frame_idx).gray = uint8(gray * 255);

                frame_idx = frame_idx + 1;
            end
        end


        function blurred_video = apply_blur(video, blur_radius)
            % Funktion zum Anwenden eines Weichzeichnungsfilters auf ein Video und Rückgabe eines unscharfen Videos
            %
            % Eingabe:
            % video - Struktur mit Graustufen-Frames
            % blur_radius - Radius des Weichzeichnungsfilters
            %
            % Ausgabe:
            % blurred_video - Struktur mit unscharfen Frames

            % Initialisieren der Ausgabevideo-Struktur
            blurred_video = struct();

            % Dynamische Kernelgröße basierend auf dem Blur-Radius
            kernel_size = 2 * ceil(2 * blur_radius) + 1;

            % Weichzeichnungsfilter erstellen
            blur_filter = fspecial('gaussian', kernel_size, blur_radius);

            % Video Frame für Frame verarbeiten
            for frame_idx = 1:length(video)
                img_gray = video(frame_idx).gray;

                % Weichzeichnungsfilter anwenden
                img_blurred = imfilter(img_gray, blur_filter, 'symmetric');

                % Unscharfen Frame speichern
                blurred_video(frame_idx).gray = img_blurred;
            end
        end

        function differential_average_video = apply_differential_average(threshold_video, window_size)
            % Funktion zur Berechnung des gleitenden Durchschnitts der Differenzen über ein Fenster von 5 Frames
            % mit Normalisierung auf das hellste Pixel im gesamten Video und Berücksichtigung der Helligkeit
            %
            % Eingabe:
            % threshold_video - 1xN struct array von Graustufenbildern
            %
            % Ausgabe:
            % differential_average_video - 1xN struct array von Graustufenbildern

            % Anzahl der Frames im Video
            num_frames = length(threshold_video);

            % Fensterbreite festlegen (5 Frames)
            half_window = floor(window_size / 2);

            % Initialisierung der Ausgabe
            differential_average_video(num_frames) = struct('gray', []);

            % Initialisierung der Liste für das globale Maximum der absoluten Differenzen
            global_max_diff = 0;

            % Loop über alle Frames, um das globale Maximum der Differenzen zu berechnen
            for i = 1:num_frames - 1
                current_frame = double(threshold_video(i).gray);
                next_frame = double(threshold_video(i + 1).gray);
                diffs = abs(next_frame - current_frame);
                global_max_diff = max(global_max_diff, max(diffs(:)));
            end

            % Falls das globale Maximum 0 ist (z.B. wenn alle Frames gleich sind), auf 1 setzen
            if global_max_diff == 0
                global_max_diff = 1;
            end

            % Loop über alle Frames im Video für die gleitende Fensterberechnung
            for i = 1:num_frames
                % Bestimmung der Start- und End-Frames für das Fenster
                start_frame = max(1, i - half_window);
                end_frame = min(num_frames, i + half_window);

                % Initialisierung der Liste für die Differenzen und die Helligkeit
                diffs = zeros(size(threshold_video(1).gray, 1), size(threshold_video(1).gray, 2), end_frame - start_frame);
                brightness = zeros(size(threshold_video(1).gray, 1), size(threshold_video(1).gray, 2), end_frame - start_frame);

                % Berechnung der Differenzen und Helligkeit für jedes Pixel im Fenster
                for j = start_frame:end_frame - 1
                    current_frame = double(threshold_video(j).gray);
                    next_frame = double(threshold_video(j + 1).gray);
                    diffs(:, :, j - start_frame + 1) = abs(next_frame - current_frame);
                    brightness(:, :, j - start_frame + 1) = current_frame; % Helligkeit des aktuellen Frames
                end

                % Berechnung des gleitenden Durchschnitts der absoluten Differenzen
                mean_diffs = mean(diffs, 3);

                % Berechnung des mittleren Helligkeitswertes im Fenster
                mean_brightness = mean(brightness, 3);

                % Invertiere die Differenzen, um geringe Bewegungen zu betonen
                inverted_diffs = 1 - (mean_diffs / global_max_diff);

                % Kombiniere die invertierten Differenzen mit der Helligkeit
                combined = inverted_diffs .* (mean_brightness / 255);

                % Normalisierung des kombinierten Wertes
                normalized_combined = combined * 255;

                % Speicherung des Ergebnisses im Output-Array
                differential_average_video(i).gray = uint8(normalized_combined);
            end
        end

        function gray_video = apply_gray_converter(video)
            % Funktion zum Umwandeln eines Videos in Graustufen
            %
            % Eingabe:
            % video - VideoReader-Objekt
            %
            % Ausgabe:
            % gray_video - Struktur mit Graustufen-Frames

            % Initialisieren der Ausgabevideo-Struktur
            gray_video = struct();
            frame_idx = 1;

            % Video Frame für Frame verarbeiten
            while hasFrame(video)
                img = readFrame(video);  % Frame lesen

                % In Graustufen umwandeln, falls das Bild farbig ist
                if size(img, 3) == 3
                    img_gray = rgb2gray(img);
                else
                    img_gray = img;
                end

                % Graustufen-Frame speichern
                gray_video(frame_idx).gray = img_gray;

                frame_idx = frame_idx + 1;
            end
        end

        function moving_average_video = apply_moving_average(threshold_video, frames)
            % Funktion zum Anwenden eines gleitenden Mittelwerts auf ein binarisiertes Video
            %
            % Eingabe:
            % threshold_video - 1xN struct array von Graustufenbildern
            % frames - Fensterbreite des gleitenden Mittelwerts in Frames
            %
            % Ausgabe:
            % moving_average_video - 1xN struct array von Graustufenbildern

            % Anzahl der Frames im Video
            num_frames = length(threshold_video);

            % Initialisierung der Ausgabe
            moving_average_video(num_frames) = struct('gray', []);

            % Loop über alle Frames im Video
            for i = 1:num_frames
                % Bestimmung der Start- und End-Frames für das gleitende Fenster
                start_frame = max(1, i - floor(frames/2));
                end_frame = min(num_frames, i + floor(frames/2));

                % Initialisierung des Akkumulators
                accumulator = zeros(size(threshold_video(1).gray));

                % Akkumulieren der Frames im gleitenden Fenster
                for j = start_frame:end_frame
                    accumulator = accumulator + double(threshold_video(j).gray);
                end

                % Berechnung des Mittelwerts
                moving_average = accumulator / (end_frame - start_frame + 1);

                % Speicherung des Ergebnisses im Output-Array
                moving_average_video(i).gray = uint8(moving_average);
            end
        end

        function threshold_video = apply_threshold(video, threshold_level)
            % Funktion zum Anwenden eines Thresholds auf ein Video und Rückgabe eines Schwarzweiß-Videos
            %
            % Eingabe:
            % video - Struktur mit Graustufen-Frames
            % threshold_level - Schwellenwert (0 bis 255) oder leer (berechnet automatisch)
            %
            % Ausgabe:
            % threshold_video - Struktur mit binarisierten Frames

            if isempty(video)
                error('Das Eingabevideo darf nicht leer sein.');
            end

            % Schwellenwert automatisch berechnen, falls nicht angegeben
            if nargin < 2 || isempty(threshold_level)
                threshold_level = GrayVideoAnalyzer.calculate_optimal_threshold(video);
            end

            % Initialisieren der Ausgabevideo-Struktur
            threshold_video = struct();

            % Video Frame für Frame verarbeiten
            for frame_idx = 1:length(video)
                img_gray = video(frame_idx).gray;

                % Threshold anwenden und zu binärem Bild konvertieren
                img_binary = imbinarize(img_gray, threshold_level / 255);  % threshold_level auf [0, 1] normieren

                % Umwandeln in 0 und 255
                img_binary = uint8(img_binary) * 255;

                % Binarisierten Frame speichern
                threshold_video(frame_idx).gray = img_binary;
            end
        end

        function threshold_level = calculate_optimal_threshold(video)
            % Funktion zum Berechnen und Rückgabe des idealen Threshold-Werts für das Bild mit den hellsten Pixeln aus einem Video
            %
            % Eingabe:
            % video - Struktur mit Graustufen-Frames
            %
            % Ausgabe:
            % threshold_level - idealer Threshold-Wert (0 bis 255)

            % Initialisieren des Bildes mit den maximalen Pixelwerten
            [height, width] = size(video(1).gray);
            max_image = zeros(height, width);

            % Video Frame für Frame verarbeiten
            for frame_idx = 1:length(video)
                img_gray = video(frame_idx).gray;

                % Aktualisieren des Bildes mit den maximalen Pixelwerten
                max_image = max(max_image, double(img_gray));
            end

            % Berechnung des optimalen Threshold-Werts mit dem Otsu-Algorithmus
            max_image_uint8 = uint8(max_image); % Umwandlung in uint8 für den Otsu-Algorithmus
            threshold_level = graythresh(max_image_uint8) * 255; % Otsu-Algorithmus liefert Wert zwischen 0 und 1, Umwandlung in 0-255
        end

        function scaled_video = apply_video_scaler(gray_video, scale_factor, frame_interval, in_frame, out_frame)
            % Funktion zum Anwenden eines Skalierers auf ein Graustufen-Video und Reduzieren der Frames
            %
            % Eingabe:
            % gray_video      - Struktur mit Graustufen-Frames (von apply_gray_converter)
            % scale_factor    - Skalierungsfaktor, z.B. 0.5 für Verkleinerung oder 2 für Vergrößerung
            % frame_interval  - Intervall für die Reduktion der Frames, z.B. 5 für jedes 5. Frame
            % in_frame        - Start-Frame (inklusiv)
            % out_frame       - End-Frame (inklusiv)
            %
            % Ausgabe:
            % scaled_video - Struktur mit skalierten und reduzierten Frames

            if nargin < 5
                error('Funktion benötigt 5 Argumente: gray_video, scale_factor, frame_interval, in_frame, out_frame');
            end

            % Begrenzungen prüfen und anpassen
            total_frames = numel(gray_video);
            in_frame = max(1, in_frame);
            out_frame = min(total_frames, out_frame);

            % Initialisierung
            scaled_video = struct('gray', {});
            output_idx = 1;

            % Durchlaufe gewünschten Bereich mit gegebenem Intervall
            for frame_idx = in_frame:frame_interval:out_frame
                img_gray = gray_video(frame_idx).gray;
                img_scaled = imresize(img_gray, scale_factor);

                scaled_video(output_idx).gray = img_scaled;
                output_idx = output_idx + 1;
            end
        end


        function cut_out_video = crop_video(gray_video, left, right, top, bottom)
            % Funktion zum Ausschneiden eines Bereichs im Graustufen-Video basierend auf Koordinaten,
            % und Anpassen der Framegröße an die neue Region.
            %
            % Eingabe:
            % left, right, top, bottom - Koordinaten des auszuschneidenden Bereichs (ROI)
            % gray_video - Struktur mit Graustufen-Frames (0-255)
            %
            % Ausgabe:
            % cut_out_video - Struktur mit Graustufen-Frames, die auf die Größe des
            %                angegebenen Bereichs (ROI) zugeschnitten sind.

            % Initialisieren der Ausgabe
            num_frames = length(gray_video);
            cut_out_video = struct('gray', {});  % Leere Struktur für das neue Video

            % Frame-Größe aus dem ersten Frame entnehmen
            if num_frames > 0 && ~isempty(gray_video(1).gray)
                [frame_height, frame_width] = size(gray_video(1).gray);
            else
                error('Das Video enthält keine gültigen Frames.');
            end

            % Anpassung der Koordinaten an die gültigen Grenzen
            left = max(1, left);                % Left darf nicht kleiner als 1 sein
            right = min(frame_width, right);    % Right darf nicht größer als frame_width sein
            bottom = max(1, bottom);            % Bottom darf nicht kleiner als 1 sein
            top = min(frame_height, top);       % Top darf nicht größer als frame_height sein

            % Überprüfen, ob die Koordinaten nach der Anpassung gültig sind
            if left >= right
                % Setze right auf left + 1, falls left >= right
                right = left + 1;
            end

            if top <= bottom
                % Setze bottom auf top - 1, falls top <= bottom
                bottom = top - 1;
            end

            % Für jedes Frame im Video
            for frame_idx = 1:num_frames
                gray_frame = gray_video(frame_idx).gray;

                if isempty(gray_frame)
                    % Falls das Frame leer ist, überspringe es
                    continue;
                end

                % Ausschneiden des Bereichs
                cut_out_frame = gray_frame(bottom:top, left:right);  % Ausschneiden des ROI

                % Speichern des ausgeschnittenen Frames in der neuen Struktur
                cut_out_video(frame_idx).gray = cut_out_frame;
            end
        end

        function cut_out_video = cut_out(roi_video, gray_video)
            % Funktion zum Ausschneiden der ROI-Bereiche aus dem Original-Graustufen-Video
            %
            % Eingabe:
            % roi_video - Struktur mit Graustufen-Frames (0 = schwarz, 255 = weiß)
            % gray_video - Struktur mit Graustufen-Frames (0-255)
            %
            % Ausgabe:
            % cut_out_video - Struktur mit Graustufen-Frames, bei denen nur die
            %                Bereiche sichtbar sind, die in roi_video weiß sind.
            %                Alle anderen Bereiche sind auf Schwarz gesetzt.

            % Fehlerüberprüfungen
            if isempty(roi_video)
                error('Das roi_video darf nicht leer sein.');
            end

            if isempty(gray_video)
                error('Das gray_video darf nicht leer sein.');
            end

            % Überprüfen, ob beide Videos die gleiche Anzahl von Frames haben
            num_frames_roi = length(roi_video);
            num_frames_gray = length(gray_video);

            if num_frames_roi ~= num_frames_gray
                error('roi_video und gray_video müssen die gleiche Anzahl von Frames haben.');
            end

            % Initialisieren der Ausgabe
            cut_out_video = gray_video;  % Kopiere die Struktur, um gleiche Felder zu behalten

            for frame_idx = 1:num_frames_roi
                roi_frame = roi_video(frame_idx).gray;
                gray_frame = gray_video(frame_idx).gray;

                if isempty(roi_frame) || isempty(gray_frame)
                    % Falls eines der Frames leer ist, setze das Ausgabeframe auf leer
                    cut_out_video(frame_idx).gray = [];
                    continue;
                end

                % Überprüfen, ob die Frames die gleiche Größe haben
                if ~isequal(size(roi_frame), size(gray_frame))
                    error('Frame %d: roi_frame und gray_frame müssen die gleiche Größe haben.', frame_idx);
                end

                % Erstellen einer binären Maske aus roi_frame
                % Annahme: roi_frame enthält nur 0 und 255
                mask = roi_frame == 255;

                % Anwenden der Maske auf das Originalgraustufenbild
                % Setze alle Pixel außerhalb der Maske auf 0
                cut_out_frame = gray_frame;  % Kopiere das Originalframe
                cut_out_frame(~mask) = 0;    % Setze Pixel außerhalb der ROI auf Schwarz

                % Speichern des ausgeschnittenen Frames
                cut_out_video(frame_idx).gray = cut_out_frame;

            end
        end

        function square_video = cut_out_square(gray_video, coord, radius)
            % Funktion zum Ausschneiden und Zuschneiden quadratischer Bereiche aus einem Graustufen-Video
            %
            % Eingabe:
            % gray_video - Struktur mit Graustufen-Frames (0-255)
            % coord      - Matrix mit Koordinaten [max_row, max_col] für jeden Frame
            % radius     - Radius des quadratischen Ausschneidebereichs
            %
            % Ausgabe:
            % square_video - Struktur mit zugeschnittenen Graustufen-Frames,
            %               die nur den quadratischen Bereich um die angegebenen
            %               Koordinaten enthalten. Falls der Bereich über die
            %               Bildgrenzen hinausgeht, wird der fehlende Teil mit
            %               Schwarz (0) aufgefüllt.

            % Fehlerüberprüfungen
            if nargin ~= 3
                error('Die Funktion erfordert drei Eingabeargumente: gray_video, coord und radius.');
            end

            if isempty(gray_video)
                error('Das gray_video darf nicht leer sein.');
            end

            if isempty(coord)
                error('Die coord darf nicht leer sein.');
            end

            if ~isnumeric(radius) || ~isscalar(radius) || radius < 0
                error('radius muss ein positiver Skalarwert sein.');
            end

            num_frames_gray = length(gray_video);
            [num_frames_coord, num_cols] = size(coord);

            if num_frames_gray ~= num_frames_coord
                error('Die Anzahl der Frames in gray_video muss mit der Anzahl der Koordinaten übereinstimmen.');
            end

            if num_cols ~= 2
                error('coord muss eine Nx2 Matrix sein, wobei jede Zeile [max_row, max_col] enthält.');
            end

            % Bestimmen der Größe des quadratischen Bereichs
            square_size = 2 * radius + 1;

            % Initialisieren der Ausgabe
            square_video(num_frames_gray).gray = [];  % Pre-allocate for speed

            for frame_idx = 1:num_frames_gray
                gray_frame = gray_video(frame_idx).gray;

                if isempty(gray_frame)
                    % Falls das Frame leer ist, setze das Ausgabeframe auf leer
                    square_video(frame_idx).gray = [];
                    continue;
                end

                % Überprüfen, ob coord innerhalb der Bildgrenzen liegt
                [num_rows, num_cols_frame] = size(gray_frame);
                center_row = coord(frame_idx, 1);
                center_col = coord(frame_idx, 2);

                if center_row < 1 || center_row > num_rows || center_col < 1 || center_col > num_cols_frame
                    error('Frame %d: Koordinaten [%d, %d] liegen außerhalb der Bildgrenzen.', ...
                        frame_idx, center_row, center_col);
                end

                % Grenzen für den quadratischen Bereich festlegen
                row_start = center_row - radius;
                row_end   = center_row + radius;
                col_start = center_col - radius;
                col_end   = center_col + radius;

                % Falls das Quadrat über die Bildgrenzen hinausragt, den Radius anpassen
                if row_start < 1
                    radius = min(radius, center_row - 1);
                    row_start = center_row - radius;
                    row_end = center_row + radius;
                end

                if row_end > num_rows
                    radius = min(radius, num_rows - center_row);
                    row_start = center_row - radius;
                    row_end = center_row + radius;
                end

                if col_start < 1
                    radius = min(radius, center_col - 1);
                    col_start = center_col - radius;
                    col_end = center_col + radius;
                end

                if col_end > num_cols_frame
                    radius = min(radius, num_cols_frame - center_col);
                    col_start = center_col - radius;
                    col_end = center_col + radius;
                end

                % Neue quadratische Größe berechnen
                square_size = 2 * radius + 1;

                % Initialisieren des zugeschnittenen Frames mit Schwarz
                square_frame = zeros(square_size, square_size, 'like', gray_frame);

                % Berechnen der tatsächlichen Schnittkoordinaten unter Berücksichtigung der Bildgrenzen
                orig_row_start = max(row_start, 1);
                orig_row_end   = min(row_end, num_rows);
                orig_col_start = max(col_start, 1);
                orig_col_end   = min(col_end, num_cols_frame);

                % Berechnen der Positionen im zugeschnittenen Frame
                tgt_row_start = orig_row_start - row_start + 1;
                tgt_row_end   = tgt_row_start + (orig_row_end - orig_row_start);
                tgt_col_start = orig_col_start - col_start + 1;
                tgt_col_end   = tgt_col_start + (orig_col_end - orig_col_start);

                % Kopieren der relevanten Pixel in das zugeschnittene Frame
                square_frame(tgt_row_start:tgt_row_end, tgt_col_start:tgt_col_end) = ...
                    gray_frame(orig_row_start:orig_row_end, orig_col_start:orig_col_end);

                % Speichern des zugeschnittenen Frames
                square_video(frame_idx).gray = square_frame;
            end
        end

        function cut_out_video = cut_out_surface(gray_video, bottom_coord, width, height)
            % Funktion zum Ausschneiden und Zuschneiden rechteckiger Bereiche aus einem Graustufen-Video
            %
            % Eingabe:
            % gray_video    - Struktur mit Graustufen-Frames (0-255)
            % bottom_coord  - Matrix mit Koordinaten [bottom_row, center_col] für jeden Frame
            % width         - Breite des auszuschneidenden Rechtecks
            % height        - Höhe des auszuschneidenden Rechtecks
            %
            % Ausgabe:
            % cut_out_video - Struktur mit zugeschnittenen Graustufen-Frames,
            %                 die nur den rechteckigen Bereich um die angegebenen
            %                 Koordinaten enthalten. Falls der Bereich über die
            %                 Bildgrenzen hinausgeht, wird der fehlende Teil mit
            %                 Schwarz (0) aufgefüllt.

            % Fehlerüberprüfungen
            if nargin ~= 4
                error('Die Funktion erfordert vier Eingabeargumente: gray_video, bottom_coord, width und height.');
            end

            if isempty(gray_video)
                error('Das gray_video darf nicht leer sein.');
            end

            if isempty(bottom_coord)
                error('Die bottom_coord darf nicht leer sein.');
            end

            if ~isnumeric(width) || ~isscalar(width) || width <= 0
                error('width muss ein positiver Skalarwert sein.');
            end

            if ~isnumeric(height) || ~isscalar(height) || height <= 0
                error('height muss ein positiver Skalarwert sein.');
            end

            num_frames_gray = length(gray_video);
            [num_frames_coord, num_cols_coord] = size(bottom_coord);

            if num_frames_gray ~= num_frames_coord
                error('Die Anzahl der Frames in gray_video muss mit der Anzahl der Koordinaten übereinstimmen.');
            end

            if num_cols_coord ~= 2
                error('bottom_coord muss eine Nx2 Matrix sein, wobei jede Zeile [bottom_row, center_col] enthält.');
            end

            % Halbe Breite und Höhe berechnen
            half_width = floor(width / 2);
            rect_height = height;

            % Initialisieren der Ausgabe
            cut_out_video(num_frames_gray).gray = [];  % Pre-allocate for speed

            for frame_idx = 1:num_frames_gray
                gray_frame = gray_video(frame_idx).gray;

                if isempty(gray_frame)
                    % Falls das Frame leer ist, setze das Ausgabeframe auf leer
                    cut_out_video(frame_idx).gray = [];
                    continue;
                end

                % Überprüfen, ob bottom_coord innerhalb der Bildgrenzen liegt
                [num_rows, num_cols_frame] = size(gray_frame);
                bottom_row = bottom_coord(frame_idx, 1);
                center_col = bottom_coord(frame_idx, 2);

                if bottom_row < 1 || bottom_row > num_rows || center_col < 1 || center_col > num_cols_frame
                    error('Frame %d: Koordinaten [%d, %d] liegen außerhalb der Bildgrenzen.', ...
                        frame_idx, bottom_row, center_col);
                end

                % Grenzen für den rechteckigen Bereich festlegen
                row_start = round(bottom_row - rect_height + 1);  % Runde die Start- und Endwerte
                row_end   = round(bottom_row);
                col_start = round(center_col - half_width);
                col_end   = round(center_col + half_width);

                % Anpassen der Grenzen, falls sie über die Bildgrenzen hinausragen
                row_start_pad = 0;
                row_end_pad = 0;
                col_start_pad = 0;
                col_end_pad = 0;

                if row_start < 1
                    row_start_pad = 1 - row_start;
                    row_start = 1;
                end

                if row_end > num_rows
                    row_end_pad = row_end - num_rows;
                    row_end = num_rows;
                end

                if col_start < 1
                    col_start_pad = 1 - col_start;
                    col_start = 1;
                end

                if col_end > num_cols_frame
                    col_end_pad = col_end - num_cols_frame;
                    col_end = num_cols_frame;
                end

                % Berechnen der tatsächlichen Größe des Rechtecks
                actual_height = row_end - row_start + 1;
                actual_width = col_end - col_start + 1;

                % Initialisieren des zugeschnittenen Frames mit Schwarz
                cut_frame = zeros(rect_height, width, 'like', gray_frame);

                % Berechnen der Start- und Endpositionen im Ziel-Frame
                target_row_start = round(1 + row_start_pad);  % Verwende round, um sicherzustellen, dass die Indizes ganze Zahlen sind
                target_row_end = round(target_row_start + actual_height - 1);

                target_col_start = round(1 + col_start_pad);
                target_col_end = round(target_col_start + actual_width - 1);

                % Kopieren der relevanten Pixel in das zugeschnittene Frame
                cut_frame(target_row_start:target_row_end, target_col_start:target_col_end) = ...
                    gray_frame(row_start:row_end, col_start:col_end);

                % Speichern des zugeschnittenen Frames
                cut_out_video(frame_idx).gray = cut_frame;
            end
        end

        function display_video(video)
            % Funktion zur Darstellung eines binarisierten Videos
            %
            % Eingabe:
            % video - Struktur mit binarisierten Frames

            if isempty(video)
                error('Das binarisierte Video darf nicht leer sein.');
            end
        end

        function roi_video = extract_roi_video(gray_video, coord_bottom, coord_side, max_coord, FrameRate)
            % Zeigt die Koordinaten in einer Schleife an und schneidet den roten Bereich aus

            figure;
            num_frames = length(coord_bottom);
            roi_video = struct('gray', []);

            cropped_frame_count = 0;

            for frame_idx = 1:num_frames
                % Extrahiere das aktuelle Bild
                frame = gray_video(frame_idx).gray;

                % Extrahiere die Koordinaten
                x_left = coord_side(frame_idx, 1);
                x_right = coord_side(frame_idx, 2);
                y_up = coord_side(frame_idx, 3);
                y_down = coord_side(frame_idx, 4);

                x_bottom = coord_bottom(frame_idx, 1);
                y_bottom = coord_bottom(frame_idx, 2);

                if all(~isnan([x_bottom, y_bottom, x_left, x_right, y_up, y_down]))
                    % Berechne die Koordinaten des maximalen Rechtecks (roter Bereich)
                    max_x_left = max(1, round(x_bottom - max_coord(1)));
                    max_x_right = min(size(frame, 2), round(x_bottom + max_coord(2)));
                    max_y_up = max(1, round(y_bottom - max_coord(3)));
                    max_y_down = min(size(frame, 1), round(y_bottom + max_coord(4)));

                    % Schneide den roten Bereich aus dem Bild aus
                    cropped_frame = frame(max_y_up:max_y_down, max_x_left:max_x_right);

                    % Speichere den ausgeschnittenen Bereich
                    cropped_frame_count = cropped_frame_count + 1;
                    roi_video(cropped_frame_count).gray = cropped_frame;
                end
            end
        end

        function rotated_video = rotate_video(gray_video, angle_rad)
            % rotate_video - Funktion zum Rotieren von Graustufen-Frames eines Videos
            %
            % Eingabe:
            % gray_video - Struktur mit Graustufen-Frames (0-255)
            % angle_rad  - Rotationswinkel in Bogenmaß (Rad)
            %
            % Ausgabe:
            % rotated_video - Struktur mit rotierten Graustufen-Frames

            % Fehlerüberprüfungen
            if nargin ~= 2
                error('Die Funktion erfordert zwei Eingabeargumente: gray_video und angle_rad.');
            end

            if isempty(gray_video)
                error('Das gray_video darf nicht leer sein.');
            end

            if ~isnumeric(angle_rad) || ~isscalar(angle_rad)
                error('angle_rad muss ein Skalarwert sein.');
            end

            % Umwandlung des Winkels von Bogenmaß in Grad
            angle_deg = rad2deg(angle_rad);

            % Initialisiere die Ausgabe-Struktur
            num_frames = length(gray_video);
            rotated_video(num_frames).gray = [];  % Pre-allocation für Geschwindigkeit

            % Frames einzeln durchlaufen und rotieren
            for frame_idx = 1:num_frames
                gray_frame = gray_video(frame_idx).gray;

                if isempty(gray_frame)
                    % Falls das Frame leer ist, setze das Ausgabeframe auf leer
                    rotated_video(frame_idx).gray = [];
                    continue;
                end

                % Frame rotieren
                rotated_frame = imrotate(gray_frame, angle_deg, 'bilinear', 'crop'); % Frame rotieren
                rotated_video(frame_idx).gray = rotated_frame; % Rotierten Frame speichern
            end
        end

        function scaled_video = scaleGrayVideo(gray_video, FrameRate)
            %  Speichereffiziente Version – identische Logik wie Original.
            %  Die Verarbeitung erfolgt in EINEM Paket, das alle Frames umfasst
            %  (chunk_size = num_frames). Damit bleibt das Ergebnis vollständig
            %  unverändert, unnötige Variablen werden aber weiterhin sofort
            %  gelöscht, um Spitzenverbrauch zu reduzieren.

            num_frames   = numel(gray_video);  % Gesamtzahl Frames
            chunk_size   = num_frames;         % Paketgröße = gesamtes Video
            values       = zeros(1, FrameRate);

            %% 1) Optimales frame_interval finden
            for frame_interval = 1:FrameRate
                total_areas = [];

                % Nur ein Durchlauf, da chunk_size = num_frames
                in_f = 1;  out_f = num_frames;

                sv   = GrayVideoConverter.apply_video_scaler(gray_video, 1, frame_interval, in_f, out_f);
                mav  = GrayVideoConverter.apply_moving_average(sv, 1);
                bv   = GrayVideoConverter.apply_blur(mav, 1);
                tv   = GrayVideoConverter.apply_threshold(bv);
                total_areas = GrayVideoAnalyzer.count_areas(tv);

                % Speicher sofort freigeben
                sv = []; mav = []; bv = []; tv = [];

                values(frame_interval) = mean(abs(diff(total_areas)));
            end

            [~, frame_interval] = max(values);
            disp("frame_interval");
            disp(frame_interval);

            %% 2) Optimale Skalierung finden
            values = zeros(1, 10);
            for scaler_factor = 1:10
                sv   = GrayVideoConverter.apply_video_scaler(gray_video, 1/scaler_factor, frame_interval, 1, num_frames);
                mav  = GrayVideoConverter.apply_moving_average(sv, 1);
                bv   = GrayVideoConverter.apply_blur(mav, 1);
                tv   = GrayVideoConverter.apply_threshold(bv);
                areas = GrayVideoAnalyzer.count_areas(tv);

                values(scaler_factor) = mean(abs(diff(areas)));

                sv = []; mav = []; bv = []; tv = []; areas = [];
            end

            [~, scaler_factor] = max(values);
            disp("scaler_factor");
            disp(scaler_factor);

            %% 3) Endgültiges skaliertes Video erzeugen (gesamter Bereich)
            scaled_video = GrayVideoConverter.apply_video_scaler(gray_video, 1/scaler_factor, frame_interval, 1, num_frames);
        end
    end
end