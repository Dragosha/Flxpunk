package src 
{
	import flash.geom.Point;
	import net.flashpunk.Entity;
	import net.flashpunk.graphics.Spritemap;
	import net.flashpunk.graphics.Tilemap;
	import net.flashpunk.masks.Grid;
	import net.flxpunk.FlxEntity;
	import net.flashpunk.FP;
	import net.flashpunk.graphics.Image;
	import net.flashpunk.World;
	import net.flxpunk.FlxPath;
	import net.flxpunk.FlxPathFinding;
	import net.flashpunk.utils.Input;
	
	/**
	 * ...
	 * @author Igor
	 */
	public class TestWorld extends World
	{
		
		[Embed(source = '../assets/default_alt.txt', mimeType = 'application/octet-stream')]	public var LEVEL:Class;
		[Embed(source='../assets/empty_tiles.png')]		public var TILES:Class;

		
		 
		public var unit:Unit;
		public var grid:Grid;
		public var pf:FlxPathFinding;
		
		public var map:Tilemap;
		public var level:Entity;
		
		public function TestWorld()	{ };
		
		/**
		 * World constructor
		 */
		override public function begin():void 
		{
			super.begin();
			
			// create a tilemap
			map = new Tilemap(TILES, 720, 480, 24, 24);
			map.loadFromString(new LEVEL());
			
			// a collision grid
			grid = new Grid(720, 480, 24, 24);
			grid.loadFromString(new LEVEL());
			
			// and a level entity with a grid as mask
			level = addGraphic(map);
			level.mask = grid;
			level.type = "solid";
			
			// create an unit
			unit=new Unit(100, 200);
			add(unit);
			
			
			// start a unit movement from one point to another
			var path:FlxPath;

			//create a pathfinding object. Pass him our collison grid
			pf = new FlxPathFinding(grid); 
			// find path
			path = pf.findPath(unit.flx.getMidpoint(), new Point(150, 200), false);
			// let's moving an unit now!
			// with speed: 30 pixels per second 
			// and move from the start of the path to the end then turn around and go back to the start, over and over.
			unit.flx.followPath(path, 30, FlxPath.PATH_YOYO);
			
			FP.watch("flx");
		}
		
		/**
		 * World update
		 */
		override public function update():void 
		{
			
			super.update();
			
			if (Input.mousePressed) {
			
				var path:FlxPath;
				path = pf.findPath(unit.flx.getMidpoint(), new Point(mouseX, mouseY), true);
				unit.flx.followPath(path, 60, FlxPath.PATH_FORWARD);
			}
		}
		
		
		/**
		 * ~Destructor
		 */
		override public function end():void 
		{
			super.end();
		}
		
		
	}

}