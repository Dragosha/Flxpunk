package net.flxpunk 
{
	
	import flash.geom.Point;
	import net.flashpunk.masks.Grid;
	import net.flashpunk.graphics.Tilemap;
	/**
	 * ...
	 * This is a pathfinding stuff
	 * used a FlashPunk Grid object as collision map
	 */
	public class FlxPathFinding
	{
		private var _grid:Grid;
		private var widthInTiles:uint;
		private var _tileHeight:uint;
		private var _tileWidth:uint;
		private var heightInTiles:uint;
		private var _point:Point;
		
		public function FlxPathFinding( grid:Grid=null) 
		{
			if (grid) {
				this.grid = grid;
			}
			_point = new Point();
		}
		
		public function set grid(g:Grid):void
		{
			_grid = g;
			
			if (_grid != null)
			{
				widthInTiles = _grid.columns;
				heightInTiles = _grid.rows;
				_tileWidth = _grid.tileWidth;
				_tileHeight = _grid.tileHeight;	
				
			}
		}
		
		public function get grid():Grid {
			return _grid;
		}
		
		
		/**
		 * Find a path through the tilemap.  Any tile with any collision flags set is treated as impassable.
		 * If no path is discovered then a null reference is returned.
		 * 
		 * @param	Start		The start point in world coordinates.
		 * @param	End			The end point in world coordinates.
		 * @param	Simplify	Whether to run a basic simplification algorithm over the path data, removing extra points that are on the same line.  Default value is true.
		 * @param	RaySimplify	Whether to run an extra raycasting simplification algorithm over the remaining path data.  This can result in some close corners being cut, and should be used with care if at all (yet).  Default value is false.
		 * 
		 * @return	A <code>FlxPath</code> from the start to the end.  If no path could be found, then a null reference is returned.
		 */
		public function findPath(Start:Point,End:Point,Simplify:Boolean=true,RaySimplify:Boolean=false):FlxPath
		{
			//figure out what tile we are starting and ending on.
			var startIndex:uint = int((Start.y-_grid.y)/_tileHeight) * widthInTiles + int((Start.x-_grid.x)/_tileWidth);
			var endIndex:uint = int((End.y-_grid.y)/_tileHeight) * widthInTiles + int((End.x-_grid.x)/_tileWidth);

			if ( startIndex == endIndex) return null;
						
			//check that the start and end are clear.
			if( _grid.getTile(Start.x, Start.y) ||
				_grid.getTile(End.x, End.y)	 )
				return null;
			
			//figure out how far each of the tiles is from the starting tile
			var distances:Array = computePathDistance(startIndex,endIndex);
			if(distances == null)
				return null;

			//then count backward to find the shortest path.
			var points:Array = new Array();
			walkPath(distances,endIndex,points);
			
			//reset the start and end points to be exact
			var node:Point;
			node = points[points.length-1] as Point;
			node.x = Start.x;
			node.y = Start.y;
			node = points[0] as Point;
			node.x = End.x;
			node.y = End.y;

			//some simple path cleanup options
			if(Simplify)
				simplifyPath(points);
			if(RaySimplify)
				raySimplifyPath(points);
			
			//finally load the remaining points into a new path object and return it
			var path:FlxPath = new FlxPath();
			var i:int = points.length - 1;
			while(i >= 0)
			{
				node = points[i--] as Point;
				if(node != null)
					path.addPoint(node,true);
			}
			return path;
		}
		
		/**
		 * Pathfinding helper function, strips out extra points on the same line.
		 *
		 * @param	Points		An array of <code>Point</code> nodes.
		 */
		protected function simplifyPath(Points:Array):void
		{
			var deltaPrevious:Number;
			var deltaNext:Number;
			var last:Point = Points[0];
			var node:Point;
			var i:uint = 1;
			var l:uint = Points.length-1;
			while(i < l)
			{
				node = Points[i];
				deltaPrevious = (node.x - last.x)/(node.y - last.y);
				deltaNext = (node.x - Points[i+1].x)/(node.y - Points[i+1].y);
				if((last.x == Points[i+1].x) || (last.y == Points[i+1].y) || (deltaPrevious == deltaNext))
					Points[i] = null;
				else
					last = node;
				i++;
			}
		}
		
		/**
		 * Pathfinding helper function, strips out even more points by raycasting from one point to the next and dropping unnecessary points.
		 * 
		 * @param	Points		An array of <code>Point</code> nodes.
		 */
		protected function raySimplifyPath(Points:Array):void
		{
			var source:Point = Points[0];
			var lastIndex:int = -1;
			var node:Point;
			var i:uint = 1;
			var l:uint = Points.length;
			while(i < l)
			{
				node = Points[i++];
				if(node == null)
					continue;
				if(ray(source,node,_point))	
				{
					if(lastIndex >= 0)
						Points[lastIndex] = null;
				}
				else
					source = Points[lastIndex];
				lastIndex = i-1;
			}
		}
		
		/**
		 * Pathfinding helper function, floods a grid with distance information until it finds the end point.
		 * NOTE: Currently this process does NOT use any kind of fancy heuristic!  It's pretty brute.
		 * 
		 * @param	StartIndex	The starting tile's map index.
		 * @param	EndIndex	The ending tile's map index.
		 * 
		 * @return	A Flash <code>Array</code> of <code>Point</code> nodes.  If the end tile could not be found, then a null <code>Array</code> is returned instead.
		 */
		protected function computePathDistance(StartIndex:uint, EndIndex:uint):Array
		{
			//Create a distance-based representation of the tilemap.
			//All walls are flagged as -2, all open areas as -1.
			var mapSize:uint = widthInTiles*heightInTiles;
			var distances:Array = new Array(mapSize);
			var i:int = 0;
			var x:uint = 0;
			var y:uint = 0;
			while(i < mapSize)
			{
				if(_grid.getTile(x,y))//_grid.getTile(i%widthInTiles,uint(i/heightInTiles))
					distances[i] = -2;
				else
					distances[i] = -1;
				i++;
				x++; if (x == widthInTiles) { x = 0; y++; }
			}
			distances[StartIndex] = 0;
			var distance:uint = 1;
			var neighbors:Array = [StartIndex];
			var current:Array;
			var currentIndex:uint;
			var left:Boolean;
			var right:Boolean;
			var up:Boolean;
			var down:Boolean;
			var currentLength:uint;
			var foundEnd:Boolean = false;
			while(neighbors.length > 0)
			{
				current = neighbors;
				neighbors = new Array();
				
				i = 0;
				currentLength = current.length;
				while(i < currentLength)
				{
					currentIndex = current[i++];
					if(currentIndex == EndIndex)
					{
						foundEnd = true;
						neighbors.length = 0;
						break;
					}
					
					//basic map bounds
					left = currentIndex%widthInTiles > 0;
					right = currentIndex%widthInTiles < widthInTiles-1;
					up = currentIndex/widthInTiles > 0;
					down = currentIndex/widthInTiles < heightInTiles-1;
					
					var index:uint;
					if(up)
					{
						index = currentIndex - widthInTiles;
						if(distances[index] == -1)
						{
							distances[index] = distance;
							neighbors.push(index);
						}
					}
					if(right)
					{
						index = currentIndex + 1;
						if(distances[index] == -1)
						{
							distances[index] = distance;
							neighbors.push(index);
						}
					}
					if(down)
					{
						index = currentIndex + widthInTiles;
						if(distances[index] == -1)
						{
							distances[index] = distance;
							neighbors.push(index);
						}
					}
					if(left)
					{
						index = currentIndex - 1;
						if(distances[index] == -1)
						{
							distances[index] = distance;
							neighbors.push(index);
						}
					}
					if(up && right)
					{
						index = currentIndex - widthInTiles + 1;
						if((distances[index] == -1) && (distances[currentIndex-widthInTiles] >= -1) && (distances[currentIndex+1] >= -1))
						{
							distances[index] = distance;
							neighbors.push(index);
						}
					}
					if(right && down)
					{
						index = currentIndex + widthInTiles + 1;
						if((distances[index] == -1) && (distances[currentIndex+widthInTiles] >= -1) && (distances[currentIndex+1] >= -1))
						{
							distances[index] = distance;
							neighbors.push(index);
						}
					}
					if(left && down)
					{
						index = currentIndex + widthInTiles - 1;
						if((distances[index] == -1) && (distances[currentIndex+widthInTiles] >= -1) && (distances[currentIndex-1] >= -1))
						{
							distances[index] = distance;
							neighbors.push(index);
						}
					}
					if(up && left)
					{
						index = currentIndex - widthInTiles - 1;
						if((distances[index] == -1) && (distances[currentIndex-widthInTiles] >= -1) && (distances[currentIndex-1] >= -1))
						{
							distances[index] = distance;
							neighbors.push(index);
						}
					}
				}
				distance++;
			}
			if(!foundEnd)
				distances = null;
			return distances;
		}
		
		/**
		 * Pathfinding helper function, recursively walks the grid and finds a shortest path back to the start.
		 * 
		 * @param	Data	A Flash <code>Array</code> of distance information.
		 * @param	Start	The tile we're on in our walk backward.
		 * @param	Points	A Flash <code>Array</code> of <code>Point</code> nodes composing the path from the start to the end, compiled in reverse order.
		 */
		protected function walkPath(Data:Array,Start:uint,Points:Array):void
		{
			Points.push(new Point(_grid.x + uint(Start%widthInTiles)*_tileWidth + _tileWidth*0.5, _grid.y + uint(Start/widthInTiles)*_tileHeight + _tileHeight*0.5));
			if(Data[Start] == 0)
				return;
			
			//basic map bounds
			var left:Boolean = Start%widthInTiles > 0;
			var right:Boolean = Start%widthInTiles < widthInTiles-1;
			var up:Boolean = Start/widthInTiles > 0;
			var down:Boolean = Start/widthInTiles < heightInTiles-1;
			
			var current:uint = Data[Start];
			var i:uint;
			if(up)
			{
				i = Start - widthInTiles;
				if((Data[i] >= 0) && (Data[i] < current))
				{
					walkPath(Data,i,Points);
					return;
				}
			}
			if(right)
			{
				i = Start + 1;
				if((Data[i] >= 0) && (Data[i] < current))
				{
					walkPath(Data,i,Points);
					return;
				}
			}
			if(down)
			{
				i = Start + widthInTiles;
				if((Data[i] >= 0) && (Data[i] < current))
				{
					walkPath(Data,i,Points);
					return;
				}
			}
			if(left)
			{
				i = Start - 1;
				if((Data[i] >= 0) && (Data[i] < current))
				{
					walkPath(Data,i,Points);
					return;
				}
			}
			if(up && right)
			{
				i = Start - widthInTiles + 1;
				if((Data[i] >= 0) && (Data[i] < current))
				{
					walkPath(Data,i,Points);
					return;
				}
			}
			if(right && down)
			{
				i = Start + widthInTiles + 1;
				if((Data[i] >= 0) && (Data[i] < current))
				{
					walkPath(Data,i,Points);
					return;
				}
			}
			if(left && down)
			{
				i = Start + widthInTiles - 1;
				if((Data[i] >= 0) && (Data[i] < current))
				{
					walkPath(Data,i,Points);
					return;
				}
			}
			if(up && left)
			{
				i = Start - widthInTiles - 1;
				if((Data[i] >= 0) && (Data[i] < current))
				{
					walkPath(Data,i,Points);
					return;
				}
			}
		}
		
		/**
		 * Shoots a ray from the start point to the end point.
		 * If/when it passes through a tile, it stores that point and returns false.
		 * 
		 * @param	Start		The world coordinates of the start of the ray.
		 * @param	End			The world coordinates of the end of the ray.
		 * @param	Result		A <code>Point</code> object containing the first wall impact.
		 * @param	Resolution	Defaults to 1, meaning check every tile or so.  Higher means more checks!
		 * @return	Returns true if the ray made it from Start to End without hitting anything.  Returns false and fills Result if a tile was hit.
		 */
		public function ray(Start:Point, End:Point, Result:Point=null, Resolution:Number=1):Boolean
		{
			var step:Number = _tileWidth;
			if(_tileHeight < _tileWidth)
				step = _tileHeight;
			step /= Resolution;
			var deltaX:Number = End.x - Start.x;
			var deltaY:Number = End.y - Start.y;
			var distance:Number = Math.sqrt(deltaX*deltaX + deltaY*deltaY);
			var steps:uint = Math.ceil(distance/step);
			var stepX:Number = deltaX/steps;
			var stepY:Number = deltaY/steps;
			var curX:Number = Start.x - stepX - _grid.x;
			var curY:Number = Start.y - stepY - _grid.y;
			var tileX:uint;
			var tileY:uint;
			var i:uint = 0;
			while(i < steps)
			{
				curX += stepX;
				curY += stepY;
				
				if((curX < 0) || (curX > _grid.width) || (curY < 0) || (curY > _grid.height))
				{
					i++;
					continue;
				}
				
				tileX = curX/_tileWidth;
				tileY = curY/_tileHeight;
				if(_grid.getTile(tileX,tileY))
				{
					//Some basic helper stuff
					tileX *= _tileWidth;
					tileY *= _tileHeight;
					var rx:Number = 0;
					var ry:Number = 0;
					var q:Number;
					var lx:Number = curX-stepX;
					var ly:Number = curY-stepY;
					
					//Figure out if it crosses the X boundary
					q = tileX;
					if(deltaX < 0)
						q += _tileWidth;
					rx = q;
					ry = ly + stepY*((q-lx)/stepX);
					if((ry > tileY) && (ry < tileY + _tileHeight))
					{
						if(Result == null)
							Result = new Point();
						Result.x = rx;
						Result.y = ry;
						return false;
					}
					
					//Else, figure out if it crosses the Y boundary
					q = tileY;
					if(deltaY < 0)
						q += _tileHeight;
					rx = lx + stepX*((q-ly)/stepY);
					ry = q;
					if((rx > tileX) && (rx < tileX + _tileWidth))
					{
						if(Result == null)
							Result = new Point();
						Result.x = rx;
						Result.y = ry;
						return false;
					}
					return true;
				}
				i++;
			}
			return true;
		}
		
	}

}