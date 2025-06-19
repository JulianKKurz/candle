classdef GUI < matlab.apps.AppBase

    % Properties
    properties (Access = public)
        UIFigure               matlab.ui.Figure
        TabGroup               matlab.ui.container.TabGroup
        DatamanagerTab         matlab.ui.container.Tab
        VideoladenButton       matlab.ui.control.Button
        SegmentPlotsTab        matlab.ui.container.Tab
        UIAxes                 matlab.ui.control.UIAxes
        UIAxes2                matlab.ui.control.UIAxes
        UIAxes3                matlab.ui.control.UIAxes
        UIAxes4                matlab.ui.control.UIAxes
        SimulationTab          matlab.ui.container.Tab
        SimulationStartButton  matlab.ui.control.Button
        SegmentsPlayButton     matlab.ui.control.Button
        CCodeexportierenTab    matlab.ui.container.Tab
        CDateispeichernButton  matlab.ui.control.Button

        avg_values             cell
        segmented_videos       cell
        video                  % VideoReader object
    end

    % Methoden zur Steuerung der Widgets
    methods (Access = private)

        function setWidgetsVisible(app, state)
            app.UIAxes.Visible = strcmp(state, 'on');
            app.UIAxes2.Visible = strcmp(state, 'on');
            app.UIAxes3.Visible = strcmp(state, 'on');
            app.UIAxes4.Visible = strcmp(state, 'on');
            app.CDateispeichernButton.Visible = state;
            app.SimulationStartButton.Visible = state;
            app.SegmentsPlayButton.Visible = state;
        end

        function setWidgetsEnabled(app, state)
            app.CDateispeichernButton.Enable = state;
            app.SimulationStartButton.Enable = state;
            app.SegmentsPlayButton.Enable = state;
        end

        function updatePlots(app)
            if isempty(app.avg_values)
                return;
            end

            % Kanal 1
            plot(app.UIAxes, app.avg_values{1});
            xlabel(app.UIAxes, 'Frame');
            ylabel(app.UIAxes, 'Pixelwert');
            ylim(app.UIAxes, [0 255]);

            % Kanal 2
            plot(app.UIAxes2, app.avg_values{2});
            xlabel(app.UIAxes2, 'Frame');
            ylabel(app.UIAxes2, 'Pixelwert');
            ylim(app.UIAxes2, [0 255]);

            % Kanal 3
            plot(app.UIAxes3, app.avg_values{3});
            xlabel(app.UIAxes3, 'Frame');
            ylabel(app.UIAxes3, 'Pixelwert');
            ylim(app.UIAxes3, [0 255]);

            % Kanal 4
            plot(app.UIAxes4, app.avg_values{4});
            xlabel(app.UIAxes4, 'Frame');
            ylabel(app.UIAxes4, 'Pixelwert');
            ylim(app.UIAxes4, [0 255]);
        end

    end

    % Callback-Methoden
    methods (Access = private)

        function closeRequest(app, src, event)
            disp('Schließe GUI und beende alle Prozesse...');
            delete(app.UIFigure);
            clear app;
        end

        function VideoladenButtonPushed(app, ~)
            try
                projectPath = pwd;
                addpath(genpath(fullfile(projectPath, 'sample_videos')));
                [file, path] = uigetfile({'*.mp4;*.avi;*.mov', 'Video Files (*.mp4, *.avi, *.mov)'}, ...
                    'Wähle ein Video aus', 'projectPath\\sample_videos');

                if isequal(file, 0)
                    disp('Benutzer hat die Dateiauswahl abgebrochen');
                else
                    app.VideoladenButton.Enable = 'off';
                    sample_video_path = fullfile(path, file);
                    disp(['Video geladen: ', file]);
                    processVideo(app, sample_video_path);
                end
            catch ME
                disp('Fehler beim Laden des Videos:');
                disp(ME.message);
            end
        end

        function processVideo(app, video_path)
            try
                app.video = VideoReader(video_path);
                numFrames = app.video.NumFrames;
                fps = app.video.FrameRate;
                disp(['Verarbeite Video mit ' num2str(numFrames) ' Frames.']);

                app.video = LightSourceConverter.apply_gray_crop_max(app.video, 20, 20);

                % Warnung, wenn keine ganzzahlige Framerate
                if abs(fps - round(fps)) > 1e-3
                    uialert(app.UIFigure, ...
                        sprintf(['Das gewählte Video hat eine nicht-ganzzahlige Framerate (%.3f fps).\n\n' ...
                        'Bitte konvertiere das Video z. B. mit ffmpeg oder Premiere Pro auf z. B. 30 fps.\n' ...
                        'Wähle alternativ ein anderes Video mit ganzzahliger Framerate.'], fps), ...
                        'Warnung: Ungültige Framerate', ...
                        'Icon', 'warning');
                    app.VideoladenButton.Enable = 'on';
                    return;
                end

                % --- Lichtquelle extrahieren und in vier Segmente zerlegen ----------------
                light_source_video          = LightSourceConverter.extract_light_source(app.video);
                [seg1, seg2, seg3, seg4]    = LightSourceConverter.segment_cropped_video(light_source_video);

                % --- Mittelwerte pro Segment berechnen -----------------------------------
                avg1 = GrayVideoAnalyzer.compute_segment_averages(seg1);
                avg2 = GrayVideoAnalyzer.compute_segment_averages(seg2);
                avg3 = GrayVideoAnalyzer.compute_segment_averages(seg3);
                avg4 = GrayVideoAnalyzer.compute_segment_averages(seg4);

                % --- globales Maximum über alle Kanäle -----------------------------------
                maxVal = max([avg1(:); avg2(:); avg3(:); avg4(:)]);

                % --- Skalierungsfaktor (8-Bit-Stretch, Div-by-Zero absichern) ------------
                if maxVal == 0
                    scale = 0;           % alle Werte bleiben Schwarz
                else
                    scale = 255 / maxVal;
                end

                % --- Skalierung anwenden, runden und in uint8 casten ----------------------
                avg1 = uint8(round(avg1 * scale));
                avg2 = uint8(round(avg2 * scale));
                avg3 = uint8(round(avg3 * scale));
                avg4 = uint8(round(avg4 * scale));

                % --- Ergebnisse in App-Strukturen ablegen ---------------------------------
                app.avg_values       = {avg1, avg2, avg3, avg4};
                app.segmented_videos = {seg1, seg2, seg3, seg4};


                updatePlots(app);
                setWidgetsVisible(app, 'on');
                setWidgetsEnabled(app, 'on');
                app.VideoladenButton.Enable = 'on';

            catch ME
                disp('Fehler beim Verarbeiten des Videos:');
                disp(ME.message);
                setWidgetsEnabled(app, 'on');
            end
        end


        function SimulationStartButtonPushed(app, ~)
            app.UIFigure.Visible = 'off';
            LightSourceConverter.play_simulation_video(app.avg_values{1}, app.avg_values{2}, app.avg_values{3}, app.avg_values{4}, app.video.FrameRate);
            app.UIFigure.Visible = 'on';
        end

        function SegmentsPlayButtonPushed(app, ~)
            app.UIFigure.Visible = 'off';
            LightSourceConverter.play_segmented_videos(app.segmented_videos{1}, app.segmented_videos{2}, app.segmented_videos{3}, app.segmented_videos{4}, app.video.FrameRate);
            app.UIFigure.Visible = 'on';
        end

        function CDateispeichernButtonPushed(app, ~)
            try
                name = "candle";
                fps = app.video.FrameRate;
                minVal = uint8(floor(min(cellfun(@min, app.avg_values))));
                maxVal = uint8(ceil(max(cellfun(@max, app.avg_values))));
                LightSourceConverter.export_candle_data(app.avg_values, name, fps, minVal, maxVal);
                disp('C-Code erfolgreich exportiert.');
            catch ME
                disp('Fehler beim Exportieren des C-Codes:');
                disp(ME.message);
            end
        end
    end

    % Komponenten-Erstellung
    methods (Access = private)

        function createComponents(app)
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 800 600];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.CloseRequestFcn = @(src, event) closeRequest(app, src, event);

            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.Position = [1 1 800 600];

            app.DatamanagerTab = uitab(app.TabGroup);
            app.DatamanagerTab.Title = 'Datamanager';

            app.VideoladenButton = uibutton(app.DatamanagerTab, 'push');
            app.VideoladenButton.Position = [310 400 180 45];
            app.VideoladenButton.Text = 'Video laden';
            app.VideoladenButton.ButtonPushedFcn = @(btn, event) VideoladenButtonPushed(app, event);

            app.SegmentPlotsTab = uitab(app.TabGroup);
            app.SegmentPlotsTab.Title = 'Segment Plots';

            app.UIAxes = uiaxes(app.SegmentPlotsTab);
            title(app.UIAxes, 'Kanal 1');
            app.UIAxes.Position = [50 320 300 200];

            app.UIAxes2 = uiaxes(app.SegmentPlotsTab);
            title(app.UIAxes2, 'Kanal 2');
            app.UIAxes2.Position = [450 320 300 200];

            app.UIAxes3 = uiaxes(app.SegmentPlotsTab);
            title(app.UIAxes3, 'Kanal 3');
            app.UIAxes3.Position = [50 60 300 200];

            app.UIAxes4 = uiaxes(app.SegmentPlotsTab);
            title(app.UIAxes4, 'Kanal 4');
            app.UIAxes4.Position = [450 60 300 200];

            app.SimulationTab = uitab(app.TabGroup);
            app.SimulationTab.Title = 'Simulation';

            app.SimulationStartButton = uibutton(app.SimulationTab, 'push');
            app.SimulationStartButton.Position = [275 350 250 50];
            app.SimulationStartButton.Text = 'Simulation starten';
            app.SimulationStartButton.ButtonPushedFcn = @(btn, event) SimulationStartButtonPushed(app, event);

            app.SegmentsPlayButton = uibutton(app.SimulationTab, 'push');
            app.SegmentsPlayButton.Position = [275 250 250 50];
            app.SegmentsPlayButton.Text = 'Segmente abspielen';
            app.SegmentsPlayButton.ButtonPushedFcn = @(btn, event) SegmentsPlayButtonPushed(app, event);

            app.CCodeexportierenTab = uitab(app.TabGroup);
            app.CCodeexportierenTab.Title = 'C-Code exportieren';

            app.CDateispeichernButton = uibutton(app.CCodeexportierenTab, 'push');
            app.CDateispeichernButton.Position = [275 200 250 50];
            app.CDateispeichernButton.Text = 'C-Datei speichern';
            app.CDateispeichernButton.ButtonPushedFcn = @(btn, event) CDateispeichernButtonPushed(app, event);
        end
    end

    % Konstruktor & Destruktor
    methods (Access = public)

        function app = GUI
            createComponents(app);
            setWidgetsVisible(app, 'off');
            app.UIFigure.Visible = 'on';
        end

        function delete(app)
            delete(app.UIFigure);
        end
    end
end
