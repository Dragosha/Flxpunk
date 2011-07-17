package net.flxpunk
{
	import net.flashpunk.Tween;
	import net.flashpunk.FP;
	import flash.geom.Point;
	import net.flashpunk.Entity;
	
	/**
	 * ...
	 * as tween
	 */
	public class FlxTween extends Tween
	{
		
		public function FlxTween(parent:Entity, complete:Function = null, type:uint = 0) 
		{
			super(0, type, complete);
			_parent = parent;
			init();
		}
		
		/**
		 * initialization
		 */
		public function init():void
		{
			velocity = new Point();
			acceleration = new Point();
			drag = new Point();
			maxVelocity = new Point(10000,10000);
			
			angle = 0;
			angularVelocity = 0;
			angularAcceleration = 0;
			angularDrag = 0;
			maxAngular = 10000;
			
			path = null;
			pathSpeed = 0;
			pathAngle = 0;
			
			deltaX = 0;
			deltaY = 0;
			
			_point = new Point();
			
			_target = 100000000;
			
			x = 0; y = 0; width = 0; height = 0;
			updateFromParent();

		}
		
		/**
		 * Updates the Tween.
		 * Place this code in an Entity update method:
		 *	 x+= myFlxTween.deltaX
		 *	 y+= myFlxTween.deltay
		 * 	 if (graphic && graphic is Image)(graphic as Image).angle = myFlxTween.angle;
		 */
		override public function update():void 
		{
			super.update();
			
			// Update attributes from the parent Entity
			updateFromParent();
			
			// path motion
			if((path != null) && (pathSpeed != 0) && (path.nodes[_pathNodeIndex] != null))
				updatePathMotion();
			
			// motion
			updateMotion();
			
		}
		
		private function updateFromParent():void 
		{
			if (_parent != null) {
				x = _parent.x;
				y = _parent.y;
				width = _parent.width;
				height = _parent.height;
			}
		}
		
		
		//-------------------------------------------------------------------------------------------
		//-------------------------------------------------------------------------------------------
		/**
		 * X coordinate 
		 * calculate in updateMotion()
		 * new x: x += deltaX;
		 */
		public var deltaX:Number;
		/**
		 * Y coordinate 
		 * calculate in updateMotion()
		 * new y: y += deltaX;
		 */
		public var deltaY:Number;
		
		//-------------------------------------------------------------------------------------------
		
		/**
		 * The basic speed of this object.
		 */
		public var velocity:Point;
		/**
		 * How fast the speed of this object is changing.
		 * Useful for smooth movement and gravity.
		 */
		public var acceleration:Point;
		/**
		 * This isn't drag exactly, more like deceleration that is only applied
		 * when acceleration is not affecting the sprite.
		 */
		public var drag:Point;
		/**
		 * If you are using <code>acceleration</code>, you can use <code>maxVelocity</code> with it
		 * to cap the speed automatically (very useful!).
		 */
		public var maxVelocity:Point;
		/**
		 * Set the angle of a sprite to rotate it.
		 * WARNING: rotating sprites decreases rendering
		 * performance for this sprite by a factor of 10x!
		 */
		public var angle:Number;
		/**
		 * This is how fast you want this sprite to spin.
		 */
		public var angularVelocity:Number;
		/**
		 * How fast the spin speed should change.
		 */
		public var angularAcceleration:Number;
		/**
		 * Like <code>drag</code> but for spinning.
		 */
		public var angularDrag:Number;
		/**
		 * Use in conjunction with <code>angularAcceleration</code> for fluid spin speed control.
		 */
		public var maxAngular:Number;
		
		
		//----------------------------------
		// Path
		//----------------------------------
		/**
		 * A reference to a path object.  Null by default, assigned by <code>followPath()</code>.
		 */
		public var path:FlxPath;
		/**
		 * The speed at which the object is moving on the path.
		 * When an object completes a non-looping path circuit,
		 * the pathSpeed will be zeroed out, but the <code>path</code> reference
		 * will NOT be nulled out.  So <code>pathSpeed</code> is a good way
		 * to check if this object is currently following a path or not.
		 */
		public var pathSpeed:Number;
		/**
		 * The angle in degrees between this object and the next node, where 0 is directly upward, and 90 is to the right.
		 */
		public var pathAngle:Number;
		/**
		 * Internal helper, tracks which node of the path this object is moving toward.
		 */
		protected var _pathNodeIndex:int;
		/**
		 * Internal tracker for path behavior flags (like looping, horizontal only, etc).
		 */
		protected var _pathMode:uint;
		/**
		 * Internal helper for node navigation, specifically yo-yo and backwards movement.
		 */
		protected var _pathInc:int;
		/**
		 * Internal flag for whether hte object's angle should be adjusted to the path angle during path follow behavior.
		 */
		protected var _pathRotate:Boolean;
		
		/**
		 * This is just a pre-allocated x-y point container to be used however you like
		 */
		protected var _point:Point;
		
		/** @private */	private var _parent:Entity;
		/** @private */	private var x:Number;
		/** @private */	private var y:Number;
		/** @private */	private var width:Number;
		/** @private */	private var height:Number;
		//-------------------------------------------------------------------------------------------
		//-------------------------------------------------------------------------------------------
		
		/**
		 * Retrieve the midpoint of this object in world coordinates.
		 * 
		 * @Point	Allows you to pass in an existing <code>FlxPoint</code> object if you're so inclined.  Otherwise a new one is created.
		 * 
		 * @return	A <code>FlxPoint</code> object containing the midpoint of this object in world coordinates.
		 */
		public function getMidpoint(point:Point=null):Point
		{
			if(point == null)
				point = new Point();
			point.x = x + width*0.5;
			point.y = y + height*0.5;
			return point;
		}
		
		
		/**
		 * Call this function to give this object a path to follow.
		 * If the path does not have at least one node in it, this function
		 * will log a warning message and return.
		 * 
		 * @param	Path		The <code>FlxPath</code> you want this object to follow.
		 * @param	Speed		How fast to travel along the path in pixels per second.
		 * @param	Mode		Optional, controls the behavior of the object following the path using the path behavior constants.  Can use multiple flags at once, for example PATH_YOYO|PATH_HORIZONTAL_ONLY will make an object move back and forth along the X axis of the path only.
		 * @param	AutoRotate	Automatically point the object toward the next node.  Assumes the graphic is pointing upward.  Default behavior is false, or no automatic rotation.
		 */
		public function followPath(Path:FlxPath,Speed:Number=100,Mode:uint=PATH_FORWARD,AutoRotate:Boolean=false):void
		{
			if (Path == null) return;
			if(Path.nodes.length <= 0)
			{
				FP.log("WARNING: Paths need at least one node in them to be followed.");
				return;
			}
			
			path = Path;
			pathSpeed = Math.abs(Speed);
			_pathMode = Mode;
			_pathRotate = AutoRotate;
			
			//get starting node
			if((_pathMode == PATH_BACKWARD) || (_pathMode == PATH_LOOP_BACKWARD))
			{
				_pathNodeIndex = path.nodes.length-1;
				_pathInc = -1;
			}
			else
			{
				_pathNodeIndex = 0;
				_pathInc = 1;
			}
		}
		
		/**
		 * Tells this object to stop following the path its on.
		 * 
		 * @param	DestroyPath		Tells this function whether to call destroy on the path object.  Default value is false.
		 */
		public function stopFollowingPath(DestroyPath:Boolean=false):void
		{
			pathSpeed = 0;
			if(DestroyPath && (path != null))
			{
				path.destroy();
				path = null;
			}
		}
		
		/**
		 * Internal function that decides what node in the path to aim for next based on the behavior flags.
		 * 
		 * @return	The node (a <code>Point</code> object) we are aiming for next.
		 */
		protected function advancePath(Snap:Boolean=true):Point
		{
			if(Snap)
			{
				var oldNode:Point = path.nodes[_pathNodeIndex];
				if(oldNode != null)
				{
					if((_pathMode & PATH_VERTICAL_ONLY) == 0)
						x = oldNode.x - width*0.5;
					if((_pathMode & PATH_HORIZONTAL_ONLY) == 0)
						y = oldNode.y - height*0.5;
				}
			}
			
			_pathNodeIndex += _pathInc;
			
			if((_pathMode & PATH_BACKWARD) > 0)
			{
				if(_pathNodeIndex < 0)
				{
					_pathNodeIndex = 0;
					pathSpeed = 0;
				}
			}
			else if((_pathMode & PATH_LOOP_FORWARD) > 0)
			{
				if(_pathNodeIndex >= path.nodes.length)
					_pathNodeIndex = 0;
			}
			else if((_pathMode & PATH_LOOP_BACKWARD) > 0)
			{
				if(_pathNodeIndex < 0)
				{
					_pathNodeIndex = path.nodes.length-1;
					if(_pathNodeIndex < 0)
						_pathNodeIndex = 0;
				}
			}
			else if((_pathMode & PATH_YOYO) > 0)
			{
				if(_pathInc > 0)
				{
					if(_pathNodeIndex >= path.nodes.length)
					{
						_pathNodeIndex = path.nodes.length-2;
						if(_pathNodeIndex < 0)
							_pathNodeIndex = 0;
						_pathInc = -_pathInc;
					}
				}
				else if(_pathNodeIndex < 0)
				{
					_pathNodeIndex = 1;
					if(_pathNodeIndex >= path.nodes.length)
						_pathNodeIndex = path.nodes.length-1;
					if(_pathNodeIndex < 0)
						_pathNodeIndex = 0;
					_pathInc = -_pathInc;
				}
			}
			else
			{
				if(_pathNodeIndex >= path.nodes.length)
				{
					_pathNodeIndex = path.nodes.length-1;
					pathSpeed = 0;
				}
			}

			return path.nodes[_pathNodeIndex];
		}
		
		/**
		 * Internal function for moving the object along the path.
		 * Generally this function is called automatically by <code>preUpdate()</code>.
		 * The first half of the function decides if the object can advance to the next node in the path,
		 * while the second half handles actually picking a velocity toward the next node.
		 */
		protected function updatePathMotion():void
		{
			//first check if we need to be pointing at the next node yet
			_point.x = x + width*0.5;
			_point.y = y + height*0.5;
			var node:Point = path.nodes[_pathNodeIndex];
			var deltaX:Number = node.x - _point.x;
			var deltaY:Number = node.y - _point.y;
			
			var horizontalOnly:Boolean = (_pathMode & PATH_HORIZONTAL_ONLY) > 0;
			var verticalOnly:Boolean = (_pathMode & PATH_VERTICAL_ONLY) > 0;
			
			if(horizontalOnly)
			{
				if(((deltaX>0)?deltaX:-deltaX) < pathSpeed*FP.elapsed)
					node = advancePath();
			}
			else if(verticalOnly)
			{
				if(((deltaY>0)?deltaY:-deltaY) < pathSpeed*FP.elapsed)
					node = advancePath();
			}
			else
			{
				if(Math.sqrt(deltaX*deltaX + deltaY*deltaY) < pathSpeed*FP.elapsed)
					node = advancePath();
			}
			
			//then just move toward the current node at the requested speed
			if(pathSpeed != 0)
			{
				//set velocity based on path mode
				_point.x = x + width*0.5;
				_point.y = y + height*0.5;
				if(horizontalOnly || (_point.y == node.y))
				{
					velocity.x = (_point.x < node.x)?pathSpeed:-pathSpeed;
					if(velocity.x < 0)
						pathAngle = -90;
					else
						pathAngle = 90;
					if(!horizontalOnly)
						velocity.y = 0;
				}
				else if(verticalOnly || (_point.x == node.x))
				{
					velocity.y = (_point.y < node.y)?pathSpeed:-pathSpeed;
					if(velocity.y < 0)
						pathAngle = 0;
					else
						pathAngle = 180;
					if(!verticalOnly)
						velocity.x = 0;
				}
				else
				{
					//pathAngle = FlxU.getAngle(_point, node);
					pathAngle = FP.angle(_point.x, _point.y, node.x, node.y);
					//FlxU.rotatePoint(0, pathSpeed, 0, 0, pathAngle, velocity);
					FP.angleXY(velocity, pathAngle, pathSpeed);
				}
				
				//then set object rotation if necessary
				if(_pathRotate)
				{
					angularVelocity = 0;
					angularAcceleration = 0;
					angle = pathAngle;
				}
			}			
		}
		
		/**
		 * Internal function for updating the position and speed of this object.
		 * Useful for cases when you need to update this but are buried down in too many supers.
		 * Does a slightly fancier-than-normal integration to help with higher fidelity framerate-independenct motion.
		 */
		protected function updateMotion():void
		{
			//var deltaX:Number;
			//var deltaY:Number;
			var velocityDelta:Number;

			velocityDelta = (computeVelocity(angularVelocity,angularAcceleration,angularDrag,maxAngular) - angularVelocity)/2;
			angularVelocity += velocityDelta; 
			angle += angularVelocity*FP.elapsed;
			angularVelocity += velocityDelta;
			
			velocityDelta = (computeVelocity(velocity.x,acceleration.x,drag.x,maxVelocity.x) - velocity.x)/2;
			velocity.x += velocityDelta;
			deltaX = velocity.x*FP.elapsed;
			velocity.x += velocityDelta;
						
			velocityDelta = (computeVelocity(velocity.y,acceleration.y,drag.y,maxVelocity.y) - velocity.y)/2;
			velocity.y += velocityDelta;
			deltaY = velocity.y*FP.elapsed;
			velocity.y += velocityDelta;
			
			// TODO: moveBy()
			//x += deltaX;
			//y += deltaY;
		}
		
		
		
		
		
		
		
		/**
		 * A tween-like function that takes a starting velocity
		 * and some other factors and returns an altered velocity.
		 * 
		 * @param	Velocity		Any component of velocity (e.g. 20).
		 * @param	Acceleration	Rate at which the velocity is changing.
		 * @param	Drag			Really kind of a deceleration, this is how much the velocity changes if Acceleration is not set.
		 * @param	Max				An absolute value cap for the velocity.
		 * 
		 * @return	The altered Velocity value.
		 */
		static public function computeVelocity(Velocity:Number, Acceleration:Number=0, Drag:Number=0, Max:Number=10000):Number
		{
			if(Acceleration != 0)
				Velocity += Acceleration*FP.elapsed;
			else if(Drag != 0)
			{
				var drag:Number = Drag*FP.elapsed;
				if(Velocity - drag > 0)
					Velocity = Velocity - drag;
				else if(Velocity + drag < 0)
					Velocity += drag;
				else
					Velocity = 0;
			}
			if((Velocity != 0) && (Max != 10000))
			{
				if(Velocity > Max)
					Velocity = Max;
				else if(Velocity < -Max)
					Velocity = -Max;
			}
			return Velocity;
		}
		
		//-------------------------------------------------------------------------------------------
		// Constants
		//-------------------------------------------------------------------------------------------
		
		/**
		 * Path behavior controls: move from the start of the path to the end then stop.
		 */
		static public const PATH_FORWARD:uint			= 0x000000;
		/**
		 * Path behavior controls: move from the end of the path to the start then stop.
		 */
		static public const PATH_BACKWARD:uint			= 0x000001;
		/**
		 * Path behavior controls: move from the start of the path to the end then directly back to the start, and start over.
		 */
		static public const PATH_LOOP_FORWARD:uint		= 0x000010;
		/**
		 * Path behavior controls: move from the end of the path to the start then directly back to the end, and start over.
		 */
		static public const PATH_LOOP_BACKWARD:uint		= 0x000100;
		/**
		 * Path behavior controls: move from the start of the path to the end then turn around and go back to the start, over and over.
		 */
		static public const PATH_YOYO:uint				= 0x001000;
		/**
		 * Path behavior controls: ignores any vertical component to the path data, only follows side to side.
		 */
		static public const PATH_HORIZONTAL_ONLY:uint	= 0x010000;
		/**
		 * Path behavior controls: ignores any horizontal component to the path data, only follows up and down.
		 */
		static public const PATH_VERTICAL_ONLY:uint		= 0x100000;
		
	}

}