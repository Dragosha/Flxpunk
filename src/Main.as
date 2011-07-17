package src
{
	import net.flashpunk.Engine;
	import net.flashpunk.FP;
	import src.TestWorld;
	
	/**
	 * ...
	 * @author Igor
	 */
	public class Main extends Engine 
	{
		
		public function Main():void 
		{
			super(700, 480, 60, false);
		}
		
		override public function init():void 
		{
			super.init();
			
			// Enable and hide a debug console
			FP.console.enable();
			//FP.console.visible = false;
			
			// Create a world
			FP.world = new TestWorld();
		}
		
	}
	
}