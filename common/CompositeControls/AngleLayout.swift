import Foundation

class PlainLayout {
    var _itemWidth: Float = 10.0;
    var _itemHeight: Float = 10.0;

    var _itemSpaceHoriz: Float = 5.0;
    var _z: Float = 5.0;

    init(itemWidth: Float, itemHeight: Float, spaceHorizontal : Float, z : Float){
        self._itemWidth = itemWidth;
        self._itemHeight = itemHeight;
        self._itemSpaceHoriz = spaceHorizontal;
        self._z = z;
    }

    func arrange(controls: Array<ISceneControl>) {
        let count = controls.count;
        let fullWidth : Float = (self._itemWidth + self._itemSpaceHoriz);
        let x0 : Float = (Float(count) * -1.0 * fullWidth) / 2.0 + (self._itemWidth / 2.0);

        for i in 0...(count-1) {
            let itm = controls[i]
            itm.setSize(self._itemWidth, height: self._itemHeight)
            let x = Float(i) * fullWidth
            itm.setPosition(x0 + x, y: 0.0, z: self._z)
        }
    }
}

class AngleLayout {
    var _angleVert: Float = 0.0;
    var _angleHoriz: Float = 0.0;

    var _itemWidth: Float = 10.0;
    var _itemHeight: Float = 10.0;

    var _itemSpaceVert: Float = 5.0;
    var _itemSpaceHoriz: Float = 5.0;

    var _maxColumns: Int = 10;

    var _isHorizontalRound: Bool = false;
    var _isVerticalRound: Bool = false;

    var _radius: Float = 0.0;

    init(radius: Float, itemWidth: Float, itemHeight: Float,
         spaceVertical: Float, spaceHorizontal: Float,
         maxColumns: Int, isHorizontalRound: Bool, isVerticalRound: Bool){
        _radius = radius;
        _itemWidth = itemWidth;
        _itemHeight = itemHeight;

        _itemSpaceHoriz = spaceHorizontal;
        _itemSpaceVert = spaceVertical;

        _isHorizontalRound = isHorizontalRound;
        _isVerticalRound = isVerticalRound;

        _maxColumns = maxColumns;
    }

    func arrange(controls: Array<ISceneControl>) {
        let count = controls.count;
        let columns = min(count, _maxColumns);
        let rows = (Int)(count / columns) + 1;

        let r2 = _radius * 2.0 - 0.001;
        let w = min(r2, _itemWidth);
        let h = min(r2, _itemHeight);

        let fw = min(r2, _itemWidth + _itemSpaceHoriz);
        let fh = min(r2, _itemHeight + _itemSpaceVert);

        var sx: Float = 0.0;
        var sy: Float = 0.0;
        var spx: Float = 0.0;
        var spy: Float = 0.0;

        if(_isHorizontalRound){
            _angleHoriz = getAngle(fw);
            spy = (-((Float)(columns - 1) * _angleHoriz) / 2.0);
        }else{
            let tmp: Float = (Float(columns) * fw);
            sx = -1.0 * tmp / 2.0;
        }

        if(_isVerticalRound){
            _angleVert = getAngle(fh);
            spx = (((Float) (rows - 1) * _angleVert) / 2.0);
        } else {
            sy = (((Float) (rows - 1) * fh) / 2.0) - fh/2.0;
        }

        var px: Float = spx;
        var py: Float = spy;

        var x: Float = sx;
        var y: Float = sy;

        var column: Int = 0;
        var row: Int = 0;

        for entity in controls {
            entity.setPosition(x, y:y, z: -1.0 * _radius);
            entity.setSize(w, height: h);
            entity.setRotation(px, yAngle: py);

            column++;

            if(column >= columns) {
                row++;
                column = 0;
                if(_isHorizontalRound){
                    py = spy;
                } else {
                    x = sx;
                }

                if(_isVerticalRound){
                    px -= _angleVert;
                } else {
                    y -= fh;
                }
            }
            else {
                if (_isHorizontalRound) {
                    py += _angleHoriz;
                } else {
                    x += fw;
                }
            }
        }
    }

    func getAngle(length: Float) -> Float {
        return acos(1.0 - pow(length, 2.0) / (pow(_radius, 2.0) * 2.0));
    }
}