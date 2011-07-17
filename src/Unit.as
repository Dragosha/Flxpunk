package src 
{
	import net.flashpunk.Entity;
	import net.flxpunk.FlxTween;
	import net.flashpunk.graphics.Spritemap;
	
	/**
	 * ...
	 * @author Igor
	 */
	public class Unit extends Entity
	{
		
		[Embed(source = '../assets/char.png')]	public var SPRITES:Class;
		/**
		 * flixel movement and path movement controller
		 */
		public var flx:FlxTween;
		
		private var spritemap:Spritemap
		
		public function Unit(x:Number,y:Number) 
		{
			super(x, y);
			
			spritemap = new Spritemap(SPRITES, 32, 32);
				spritemap.add ("idle", [0, 2,2,2], 1);
				spritemap.add("walk", [3,4,5,6], 10);
				spritemap.play("walk");
				spritemap.centerOO();
				
			graphic = spritemap;
			
			flx = new FlxTween(this);
			addTween(flx, true);
			flx.drag.x = 400;
			flx.drag.y = 400;
		}
		
		override public function update():void 
		{
			super.update();
			//flx.update();
			
			// move!
			
			x += flx.deltaX;
			y += flx.deltaY;
			
			// if collision need:
			//moveBy(flx.deltaX, flx.deltaY, "solid");
			
			spritemap.angle = flx.angle;
			
			// view!
			if (flx.velocity.x == 0 && flx.velocity.y==0) spritemap.play("idle");
			else spritemap.play("walk");
			
			if (flx.velocity.x < 0) spritemap.flipped = true;
			else spritemap.flipped = false;
		}
		
	}

}