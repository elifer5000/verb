package verb;

import verb.eval.types.CurveData.Point;
using Lambda;

@:expose("BoundingBox")
class BoundingBox {

    public static var TOLERANCE : Float = 1e-4;
    var initialized : Bool = false;
    var dim : Int = 3;
    var min : Point;
    var max : Point;

    // ###new BoundingBox([ points ])
    //
    // BoundingBox Constructor
    //
    // **params**
    // + *Array*, Points to add, if desired.  Otherwise, will not be initialized until add is called.

    public function new( pts : Array<Point> = null ) {

        this.dim = 3;
        this.min = null;
        this.max = null;

        if ( pts != null ) {
            this.addRange( pts );
        }
    }

    // ####fromPoint( point )
    //
    // Create a bounding box initialized with a single element
    //
    // **params**
    // + *Array*, A array of numbers
    //
    // **returns**
    // + *Object*, This BoundingBox for chaining
    //

    public function fromPoint( pt ){
        var bb = new verb.BoundingBox(null);
        bb.add( pt );
        return bb;
    }

    // ####add( point )
    //
    // Adds a point to the bounding box, expanding the bounding box if the point is outside of it.
    // If the bounding box is not initialized, this method has that side effect.
    //
    // **params**
    // + *Array*, A length-n array of numbers
    //
    // **returns**
    // + *Object*, This BoundingBox for chaining
    //

    public function add( point : Point ) : BoundingBox
    {
        if ( !this.initialized )
        {
            this.dim = point.length;
            this.min = point.slice(0);
            this.max = point.slice(0);
            this.initialized = true;
            return this;
        }

        var i = 0, l = this.dim;

        for (i in 0...l){
            if (point[i] > this.max[i] )
            this.max[i] = point[i];
        }

        for (i in 0...l){
            if (point[i] < this.min[i] )
            this.min[i] = point[i];
        }

        return this;

    }

    // ####addRange( points, callback )
    //
    // Asynchronously add an array of points to the bounding box
    //
    // **params**
    // + *Array*, An array of length-n array of numbers
    // + *Function*, Function to call when all of the points in array have been added.  The only parameter to this
    // callback is this bounding box.
    //

    public function addRange( points : Array<Point> ) : BoundingBox
    {
        var l = points.length;

        for (i in 0...l){
            this.add(points[i]);
        }

        return this;
    }

    // ####contains( point )
    //
    // Determines if point is contained in the bounding box
    //
    // **params**
    // + the point
    // + the tolerance
    //
    // **returns**
    // + *Boolean*, true if the two intervals overlap, otherwise false
    //

    public function contains(point : Point, tol : Float = -1) : Bool {

        if ( !this.initialized )
        {
            return false;
        }

        return this.intersects( new verb.BoundingBox([point]), tol );
    }

    // ####intervalsOverlap( a1, a2, b1, b2 )
    //
    // Determines if two intervals on the real number line intersect
    //
    // **params**
    // + Beginning of first interval
    // + End of first interval
    // + Beginning of second interval
    // + End of second interval
    //
    // **returns**
    // + *Boolean*, true if the two intervals overlap, otherwise false
    //

    public static function intervalsOverlap( a1 : Float, a2: Float, b1: Float, b2: Float, tol : Float = -1 ) : Bool {

        var tol = tol < 0 ? TOLERANCE : tol
        , x1 = Math.min(a1, a2) - tol
        , x2 = Math.max(a1, a2) + tol
        , y1 = Math.min(b1, b2) - tol
        , y2 = Math.max(b1, b2) + tol;

        return (x1 >= y1 && x1 <= y2) || (x2 >= y1 && x2 <= y2) || (y1 >= x1 && y1 <= x2) || (y2 >= x1 && y2 <= x2) ;
    }

    // ####intersects( bb )
    //
    // Determines if this bounding box intersects with another
    //
    // **params**
    // + *Object*, BoundingBox to check for intersection with this one
    //
    // **returns**
    // + *Boolean*, true if the two bounding boxes intersect, otherwise false
    //

    public function intersects( bb : BoundingBox, tol : Float = -1 ) {

        if ( !this.initialized || !bb.initialized ) return false;

        var a1 = min
        , a2 = max
        , b1 = bb.min
        , b2 = bb.max;

        for (i in 0...dim){
            if (!intervalsOverlap(a1[i], a2[i], b1[i], b2[i], tol )) return false;
        }

        return true;
    }

    // ####clear( bb )
    //
    // Clear the bounding box, leaving it in an uninitialized state.  Call add, addRange in order to
    // initialize
    //
    // **returns**
    // + this BoundingBox for chaining
    //

    public function clear() : BoundingBox {
        this.initialized = false;
        return this;
    }

    // ####getLongestAxis( bb )
    //
    // Get longest axis of bounding box
    //
    // **returns**
    // + Index of longest axis
    //

    public function getLongestAxis() : Int {

        var max = 0.0;
        var id = 0;

        for ( i in 0...dim ){
            var l = this.getAxisLength(i);
            if (l > max) {
                max = l;
                id = i;
            }
        }

        return id;
    }

    // ####getAxisLength( i )
    //
    // Get length of given axis.
    //
    // **params**
    // + Index of axis to inspect (between 0 and 2)
    //
    // **returns**
    // + Length of the given axis.  If axis is out of bounds, returns 0.
    //

    public function getAxisLength( i : Int ) : Float {
        if (i < 0 || i > this.dim-1) return 0.0;
        return Math.abs( this.min[i] - this.max[i] );
    }

    // ####intersect( bb )
    //
    // Compute the boolean intersection of this with another axis-aligned bounding box.  If the two
    // bounding boxes do not intersect, returns null.
    //
    // **params**
    // + *Object*, BoundingBox to intersect with
    //
    // **returns**
    // + *Object*, The bounding box formed by the intersection or null if there is no intersection.
    //

    public function intersect( bb : BoundingBox, tol : Float ) : BoundingBox {

        if ( !this.initialized ) return null;

        var a1 = min
        , a2 = max
        , b1 = bb.min
        , b2 = bb.max;

        if ( !this.intersects( bb, tol ) ) return null;

        var maxbb = []
        , minbb = [];

        for (i in 0...dim){
            maxbb.push( Math.min( a2[i], b2[i] ) );
            minbb.push( Math.max( a1[i], b1[i] ) );
        }

        return new BoundingBox([minbb, maxbb]);
    }

}