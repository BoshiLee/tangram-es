/* ----------------------------------------------------------------------------
 * This file was automatically generated by SWIG (http://www.swig.org).
 * Version 3.0.3
 *
 * Do not make changes to this file unless you know what you are doing--modify
 * the SWIG interface file instead.
 * ----------------------------------------------------------------------------- */

package com.mapzen.tangram;

import java.util.List;

public class MapData extends DataSource {
    private long swigCPtr;
    private boolean swigCMemOwnDerived;

    protected MapData(long cPtr, boolean cMemoryOwn) {
        super(TangramJNI.MapData_SWIGSmartPtrUpcast(cPtr), true);
        swigCMemOwnDerived = cMemoryOwn;
        swigCPtr = cPtr;
    }

    protected static long getCPtr(MapData obj) {
        return (obj == null) ? 0 : obj.swigCPtr;
    }

    protected void finalize() {
        delete();
    }

    public synchronized void delete() {
        if (swigCPtr != 0) {
            if (swigCMemOwnDerived) {
                swigCMemOwnDerived = false;
                TangramJNI.delete_MapData(swigCPtr);
            }
            swigCPtr = 0;
        }
        super.delete();
    }


    /**
     * Construct a new MapData object for adding drawable data to the map
     * @param name Name of the data source in the scene file for styling this
     *             object's data
     */
    public MapData(String name) {
        this(TangramJNI.new_MapData(name, ""), true);
    }

    /**
     * Remove all data from this source
     * @return This object, for chaining
     */
    public MapData clear() {
        clearJNI();
        return this;
    }

    /**
     * Add geometry from a GeoJSON string to this data source
     * @param data String of GeoJSON containing a Feature or FeatureCollection
     * @return This object, for chaining
     */
    public MapData addGeoJSON(String data) {
        addData(data);
        return this;
    }

    /**
     * Add a point geometry to this data source
     * @param point LngLat with the coordinates of the point
     * @return This object, for chaining
     */
    public MapData addPoint(Properties props, LngLat point) {
        addPointJNI(props, point);
        return this;
    }

    /**
     * Add a line geometry to this data source
     * @param line List of LngLat points comprising the line
     * @return This object, for chaining
     */
    public MapData addLine(Properties props, List<LngLat> line) {
        // need to concatenate points
        Coordinates coords = new Coordinates();
        for (LngLat point : line) {
            coords.add(point);
        }
        addLineJNI(props, coords);
        return this;
    }

    public MapData addLine(Properties props, Coordinates line) {
        addLineJNI(props, line);
        return this;
    }

    /**
     * Add a polygon geometry to this data source
     * @param polygon List of lines of LngLat points, where each line represents
     *                a ring in the polygon as described in the GeoJSON spec
     * @return This object, for chaining
     */
    public MapData addPolygon(Properties props, List<List<LngLat>> polygon) {
        Polygon poly = new Polygon();

        // for (List<LngLat> ring : polygon) {
        //     Coordinates out = new Coordinates();
        //     for (LngLat point : ring) {
        //         out.add(point);
        //     }
        //     poly.add(out);
        // }

        // TODO add method to add empty ring and get handle to it.
        Coordinates dummy = new Coordinates();
        int rings = 0;

        for (List<LngLat> ring : polygon) {
            poly.add(dummy);

            Coordinates out = poly.get(rings);

            for (LngLat point : ring) {
                out.add(point);
            }
            rings++;
        }
        addPolyJNI(props, poly);
        return this;
    }

    public MapData addPolygon(Properties props, Polygon polygon) {
        addPolyJNI(props, polygon);
        return this;
    }

    public MapData(String _name, String _url) {
        this(TangramJNI.new_MapData(_name, _url), true);
    }

    public void addData(String _data) {
        TangramJNI.MapData_addData(swigCPtr, this, _data);
    }

    private void addPointJNI(Properties props, LngLat point) {
        TangramJNI.MapData_addPointJNI(swigCPtr, this, Properties.getCPtr(props), props, point);
    }

    private void addLineJNI(Properties props, Coordinates line) {
        TangramJNI.MapData_addLineJNI(swigCPtr, this, Properties.getCPtr(props), props, Coordinates.getCPtr(line), line);
    }

    private void addPolyJNI(Properties props, Polygon polygon) {
        TangramJNI.MapData_addPolyJNI(swigCPtr, this, Properties.getCPtr(props), props, Polygon.getCPtr(polygon), polygon);
    }

}
