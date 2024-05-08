package options;

import states.MainMenuState;
import backend.StageData;
import mobile.substates.MobileControlSelectSubState;
#if (target.threaded)
import sys.thread.Thread;
import sys.thread.Mutex;
#end

class OptionsState extends MusicBeatState
{
	var options:Array<String> = [
		'Note Colors',
		'Controls',
		'Adjust Delay and Combo',
		'Graphics',
		'Visuals',
		'Gameplay'
		#if TRANSLATIONS_ALLOWED , 'Language' #end
		,'Mobile Options'
	];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;
	public static var onPlayState:Bool = false;
	var tipText:FlxText;
	#if (target.threaded) var mutex:Mutex = new Mutex(); #end

	function openSelectedSubstate(label:String) {
		if (label != "Adjust Delay and Combo"){
			removeVirtualPad();
			persistentUpdate = false;
		}
		switch(label)
		{
			case 'Note Colors':
				openSubState(new options.NotesSubState());
			case 'Controls':
				openSubState(new options.ControlsSubState());
			case 'Graphics':
				openSubState(new options.GraphicsSettingsSubState());
			case 'Visuals':
				openSubState(new options.VisualsSettingsSubState());
			case 'Gameplay':
				openSubState(new options.GameplaySettingsSubState());
			case 'Adjust Delay and Combo':
				MusicBeatState.switchState(new options.NoteOffsetState());
			case 'Mobile Options':
				openSubState(new mobile.options.MobileOptionsSubState());
			case 'Language':
				openSubState(new options.LanguageSubState());
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.color = 0xFFea71fd;
		bg.updateHitbox();

		bg.screenCenter();
		add(bg);

		tipText = new FlxText(150, FlxG.height - 24, 0, Language.getPhrase('open_mobileC_menu', 'Press ${controls.mobileC ? "C" : "CTRL"} to Go Mobile Controls Menu'), 16);
		tipText.setFormat("VCR OSD Mono", 17, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tipText.borderSize = 1.25;
		tipText.scrollFactor.set();
		tipText.antialiasing = ClientPrefs.data.antialiasing;
		add(tipText);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (num => option in options)
		{
			var optionText:Alphabet = new Alphabet(0, 0, Language.getPhrase('options_$option', option), true);
			optionText.screenCenter();
			optionText.y += (92 * (num - (options.length / 2))) + 45;
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true);
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true);
		add(selectorRight);

		changeSelection();
		ClientPrefs.saveSettings();

		addVirtualPad('UP_DOWN', 'A_B_C');

		#if (target.threaded)
		Thread.create(()->{
			mutex.acquire();

			for (music in VisualsSettingsSubState.pauseMusics)
			{
				if (music.toLowerCase() != "none")
					Paths.music(Paths.formatToSongPath(music));
			}

			mutex.release();
		});
		#end

		super.create();
	}

	override function closeSubState()
	{
		super.closeSubState();
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end
		ClientPrefs.saveSettings();
		ClientPrefs.loadPrefs();
		controls.isInSubstate = false;
        removeVirtualPad();
		addVirtualPad('UP_DOWN', 'A_B_C');
		persistentUpdate = true;
	}

    var exiting:Bool = false;
	override function update(elapsed:Float) {
		super.update(elapsed);

		if(!exiting){
			if (controls.UI_UP_P)
				changeSelection(-1);
			if (controls.UI_DOWN_P)
				changeSelection(1);

			if (controls.BACK)
			{
				exiting = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				if(onPlayState)
				{
					StageData.loadDirectory(PlayState.SONG);
					LoadingState.loadAndSwitchState(new PlayState());
					FlxG.sound.music.volume = 0;
				}
				else MusicBeatState.switchState(new MainMenuState());
			}
			else if (controls.ACCEPT) openSelectedSubstate(options[curSelected]);
	
			if (virtualPad.buttonC.justPressed || FlxG.keys.justPressed.CONTROL) {
				persistentUpdate = false;
				openSubState(new MobileControlSelectSubState());
			}
		}
	}
	
	function changeSelection(change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);

		for (num => item in grpOptions.members)
		{
			item.targetY = num - curSelected;
			item.alpha = 0.6;
			if (item.targetY == 0)
			{
				item.alpha = 1;
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	override function destroy()
	{
		ClientPrefs.loadPrefs();
		super.destroy();
	}
}
