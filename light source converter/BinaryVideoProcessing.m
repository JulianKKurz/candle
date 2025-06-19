classdef BinaryVideoProcessing
    methods(Static)
        function binary_average_video = apply_binary_average(threshold_video, frames)
            % Funktion zum Anwenden eines gleitenden Fensters auf ein Video.
            % Ein Pixel wird nur dann weiß gesetzt, wenn er im gesamten Fenster weiß ist.
            %
            % Eingabe:
            % threshold_video - 1xN struct array von Graustufenbildern (Werte 0 bis 255)
            % frames - Fensterbreite des gleitenden Fensters in Frames
            %
            % Ausgabe:
            % binary_average_video - 1xN struct array von Graustufenbildern (Werte 0 bis 255)

            % Anzahl der Frames im Video
            num_frames = length(threshold_video);

            % Initialisierung der Ausgabe
            binary_average_video = struct('gray', cell(1, num_frames));

            % Loop über alle Frames im Video
            for i = 1:num_frames
                % Bestimmung der Start- und End-Frames für das gleitende Fenster
                start_frame = max(1, i - floor(frames/2));
                end_frame = min(num_frames, i + floor(frames/2));

                % Initialisierung der Binärakkumulierung
                % Hier verwenden wir `true` für alle Pixel, die immer weiß bleiben sollen.
                always_white = true(size(threshold_video(1).gray));

                % Überprüfen der Pixel in allen Frames des gleitenden Fensters
                for j = start_frame:end_frame
                    % Normierung der Graustufenwerte auf den Bereich [0, 1]
                    normalized_frame = double(threshold_video(j).gray) / 255;

                    % Binarisierung: alle Pixel >= 0.5 als 1 (weiß), sonst 0 (schwarz)
                    binary_frame = normalized_frame >= 0.5;

                    % UND-Verknüpfung: Nur Pixel beibehalten, die in allen Frames des Fensters weiß sind
                    always_white = always_white & binary_frame;
                end

                % Ergebnis ist ein Bild, das nur weiße Pixel enthält, die im gesamten Fenster weiß blieben
                % Skalierung zurück auf den Bereich [0, 255]
                binary_average_video(i).gray = uint8(always_white) * 255;
            end
        end

        function shapeed_video = apply_shape(binary_video)
            % Funktion zur Verarbeitung des Videos im Bereich 0 bis 255 und Rückgabe eines Videos,
            % bei dem nur die Kontur der ersten weißen Fläche erhalten bleibt und das Innere schwarz ist.
            %
            % Eingabe:
            % binary_video - Struktur mit Frames im Bereich 0 bis 255
            %
            % Ausgabe:
            % shapeed_video - Struktur mit Frames, bei denen nur die Kontur der ersten weißen Fläche bleibt

            % Initialisieren der Ausgabevideo-Struktur
            shapeed_video = struct();

            % Video Frame für Frame verarbeiten
            for frame_idx = 1:length(binary_video)
                % Hole das Frame und wandle es in binär um (Schwellenwert auf 128 gesetzt)
                img_binary_threshold = binary_video(frame_idx).gray;
                img_binary_threshold = img_binary_threshold > 128; % Binär machen: 0 oder 1

                % Initialisieren des Ausgabe-Bilds mit Schwarz (0)
                img_shape = zeros(size(img_binary_threshold));

                % Scannen von oben nach unten, um das Ende der ersten weißen Fläche zu finden
                [rows, ~] = size(img_binary_threshold);
                found_first_white = false;

                for r = 1:rows
                    if any(img_binary_threshold(r, :))
                        found_first_white = true;
                    elseif found_first_white
                        % Kopiere die erste weiße Fläche
                        first_area = img_binary_threshold(1:r-1, :);

                        % Finde die Kontur der ersten weißen Fläche
                        first_area_shape = bwperim(first_area);

                        % Setze das Ausgabe-Bild auf die Kontur der ersten weißen Fläche
                        img_shape(1:r-1, :) = first_area_shape;
                        break;
                    end
                end

                % Wenn keine weiße Fläche gefunden wurde, setze das gesamte Bild auf schwarz
                if ~found_first_white
                    img_shape(:) = 0;
                end

                % Skaliere das Ergebnis zurück auf den Bereich 0 bis 255
                img_shape = uint8(img_shape * 255);

                % Verarbeiteten Frame speichern
                shapeed_video(frame_idx).gray = img_shape;
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

        function white_pixel_counts = count_bottom_white_pixels(threshold_video)
            % Funktion zum Zählen der weißen Pixel an der untersten Stelle der weißen Fläche
            %
            % Eingabe:
            % threshold_video - Struktur mit binarisierten Frames
            %
            % Ausgabe:
            % white_pixel_counts - Liste mit der Anzahl der weißen Pixel an der untersten
            % Stelle der weißen Fläche für jedes Frame

            % Initialisieren der Ergebnisliste
            white_pixel_counts = [];

            % Video Frame für Frame verarbeiten
            for frame_idx = 1:length(threshold_video)
                binary_image = threshold_video(frame_idx).gray;

                % Initialisieren der Variable zur Speicherung der Pixelanzahl
                count_white_pixels = 0;

                % Von unten nach oben durch das Bild iterieren
                for row_idx = size(binary_image, 1):-1:1
                    % Überprüfen, ob die aktuelle Zeile weiße Pixel enthält
                    if any(binary_image(row_idx, :) == 255)
                        % Anzahl der weißen Pixel in dieser Zeile zählen
                        count_white_pixels = sum(binary_image(row_idx, :) == 255);
                        break; % Schleife beenden, da die unterste weiße Zeile gefunden wurde
                    end
                end

                % Anzahl der weißen Pixel für dieses Frame zur Liste hinzufügen
                white_pixel_counts = [white_pixel_counts, count_white_pixels];
            end
        end

        function bottom_line_video = erase_bottom_line(threshold_video, lines)
            % Funktion zum zeilenweisen Entfernen von Pixeln von unten nach oben in der weißen Fläche
            %
            % Eingabe:
            % threshold_video - Struktur mit binarisierten Frames
            % lines - Anzahl der Zeilen, die von unten entfernt werden sollen
            %
            % Ausgabe:
            % bottom_line_video - Struktur mit Frames, bei denen von unten die angegebene Anzahl von Zeilen der weißen Fläche entfernt wurde

            % Initialisieren der Ergebnisstruktur
            bottom_line_video = threshold_video; % Kopiere die Struktur

            % Video Frame für Frame verarbeiten
            for frame_idx = 1:length(threshold_video)
                binary_image = threshold_video(frame_idx).gray;

                % Erstellen einer Kopie des binären Bildes zum Bearbeiten
                modified_image = binary_image;

                % Anzahl der bereits entfernten Zeilen initialisieren
                lines_removed = 0;

                % Von unten nach oben durch das Bild iterieren
                for row_idx = size(binary_image, 1):-1:1
                    % Überprüfen, ob die aktuelle Zeile weiße Pixel enthält
                    if any(binary_image(row_idx, :) == 255)
                        % Setze die weißen Pixel in dieser Zeile auf schwarz
                        modified_image(row_idx, binary_image(row_idx, :) == 255) = 0;
                        lines_removed = lines_removed + 1;
                    end

                    % Überprüfen, ob die gewünschte Anzahl von Zeilen entfernt wurde
                    if lines_removed >= lines
                        break; % Schleife beenden
                    end
                end

                % Speichere das modifizierte Bild im Ergebnis
                bottom_line_video(frame_idx).gray = modified_image;
            end
        end

        function roi_video = extract_area(threshold_video, brightest_coords)
            % Funktion zum Extrahieren der weißen Fläche, die den hellsten Pixel enthält, in jedem Frame eines Videos
            %
            % Eingabe:
            % threshold_video - Struktur mit Graustufen-Frames (0 = schwarz, 255 = weiß)
            % brightest_coords - Nx2 Matrix mit den Zeilen- und Spaltenkoordinaten des hellsten Pixels in jedem Frame
            %
            % Ausgabe:
            % roi_video - Struktur mit Graustufen-Frames, bei denen nur die weiße Fläche, die den hellsten Pixel enthält, sichtbar ist

            % Fehlerüberprüfungen
            if isempty(threshold_video)
                error('Das Eingabevideo darf nicht leer sein.');
            end

            if size(brightest_coords, 2) ~= 2
                error('brightest_coords muss eine Nx2 Matrix sein.');
            end

            num_frames = length(threshold_video);
            if size(brightest_coords, 1) ~= num_frames
                error('Die Anzahl der Zeilen in brightest_coords muss der Anzahl der Frames im Video entsprechen.');
            end

            % Initialisieren der Ausgabe
            roi_video = threshold_video;  % Kopiere die Struktur, um gleiche Felder zu behalten

            for frame_idx = 1:num_frames
                img_gray = threshold_video(frame_idx).gray;

                if isempty(img_gray) || size(img_gray, 1) == 0 || size(img_gray, 2) == 0
                    % Falls das Bild leer oder ungültig ist, setze das ROI-Bild ebenfalls leer
                    roi_video(frame_idx).gray = [];
                    continue;
                end

                row = brightest_coords(frame_idx, 1);
                col = brightest_coords(frame_idx, 2);

                if isnan(row) || isnan(col)
                    % Falls die Koordinate ungültig ist, setze das ROI-Bild auf schwarz
                    roi_frame = zeros(size(img_gray), 'like', img_gray);
                else
                    % Erstelle eine binäre Maske aus dem Graustufenbild
                    binary_img = img_gray == 255;

                    % Überprüfe, ob die Koordinate innerhalb der Bildgrenzen liegt
                    if row < 1 || row > size(binary_img,1) || col < 1 || col > size(binary_img,2)
                        warning('Frame %d: Koordinate (%d, %d) liegt außerhalb der Bildgrenzen.', frame_idx, row, col);
                        roi_frame = zeros(size(img_gray), 'like', img_gray);
                    else
                        % Finde die verbundenen Komponenten im binären Bild
                        CC = bwconncomp(binary_img);

                        % Finde die Komponente, die die gegebene Koordinate enthält
                        component_idx = 0;
                        for k = 1:CC.NumObjects
                            [rows, cols] = ind2sub(size(binary_img), CC.PixelIdxList{k});
                            if any(rows == row & cols == col)
                                component_idx = k;
                                break;
                            end
                        end

                        if component_idx == 0
                            % Falls keine Komponente gefunden wurde, setze das ROI-Bild auf schwarz
                            warning('Frame %d: Keine verbundene Komponente gefunden, die die Koordinate (%d, %d) enthält.', frame_idx, row, col);
                            roi_frame = zeros(size(img_gray), 'like', img_gray);
                        else
                            % Erstelle eine Maske für die gefundene Komponente
                            roi_mask = false(size(binary_img));
                            roi_mask(CC.PixelIdxList{component_idx}) = true;

                            % Erzeuge das ROI-Bild: weiße Fläche an der Maske-Position, sonst schwarz
                            roi_frame = uint8(zeros(size(img_gray)));
                            roi_frame(roi_mask) = 255;
                        end
                    end
                end

                % Speichern des ROI-Frames
                roi_video(frame_idx).gray = roi_frame;
            end
        end
    end
end