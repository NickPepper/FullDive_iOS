//
// Created by Alexey Suvorov on 4/26/15.
//

#import <Foundation/Foundation.h>


@interface FDButton : FDControl <FDIControl>
- (instancetype) initWithResourceImage: (NSString*) name;
- (void) recalculatePosition;
- (void) initControl;
- (void) update:(long)delta;
- (void) draw:(GLKMatrix4)view headView:(GLKMatrix4)headView perspective:(GLKMatrix4)perspective;
- (void) focus;
- (void) unfocus;

@end

/*

public class AsyncButton extends Control {
    private static final int COORDS_PER_VERTEX = 3;
    private static final float MAX_LAG_THRESHOLD = 5000;
    private int glProgram;
    private boolean mIsEnable = true;

    protected final Context ctx;
    private final ImageProvider imageProvider;
    protected int texture = 0;

    private float targetScale = 1f;
    private float scale = 1f;
    private float scaleSpeed = 1.4f;

    private float targetAlpha = 1f;
    private float alpha = 1f;
    private float alphaSpeed = 1.4f;
    private boolean mIsTextureLoaded = false;
    private Bitmap mBitmap = null;

    private FloatBuffer pTexCoord;
    private FloatBuffer rectangle;
    private WorldParams worldParams;
    private boolean visibility = true;

    public AsyncButton(IWorldObjectEventListener eventListener, final Context ctx, final int resourceId) {
        this(eventListener, ctx, new ResourceImageProvider(ctx, resourceId));
    }

    public AsyncButton(IWorldObjectEventListener eventListener, final Context ctx, final Drawable icon) {
        this(eventListener, ctx, new ResourceImageProvider(ctx, icon));
    }

    public AsyncButton(IWorldObjectEventListener eventListener, Context ctx, ImageProvider imageProvider) {
        super(eventListener);

        this.ctx = ctx;
        this.imageProvider = imageProvider;

        setPosition(0, 0, 0);
    }

    private void setTextureLoaded() {
        mIsTextureLoaded = true;
    }

    private static void setTextureImage(int id, Bitmap bitmap) {
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, id);
        // Set filtering
        GLES20.glTexParameterf(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_NEAREST);
        GLES20.glTexParameterf(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_NEAREST);
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE);
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE);
        // Load the bitmap into the bound texture.
        android.opengl.GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, bitmap, 0);
    }

    public void update(long delta) {
        super.update(delta);

        if (this.scale != this.targetScale) {
            float scale_k = Math.min((Math.min(MAX_LAG_THRESHOLD, delta) / 1000f) * this.scaleSpeed,
                    Math.abs(this.scale - this.targetScale));
            this.scale += scale_k * (this.scale < this.targetScale ? 1f : -1f);
        }
        if (mIsTextureLoaded && this.alpha != this.targetAlpha) {
            float alpha_k = Math.min((Math.min(MAX_LAG_THRESHOLD, delta) / 1000f) * this.alphaSpeed,
                    Math.abs(this.alpha - this.targetAlpha));
            this.alpha += alpha_k * (this.alpha < this.targetAlpha ? 1f : -1f);
        }

    }

    @Override
    public void draw(float[] view, float[] headView, float[] perspective) {
        if(!this.visibility) return;

        if (!mIsTextureLoaded) {
            if (mBitmap == null) return;
            try {
                texture = GLUtils.GenerateGlId();
                setTextureImage(texture, mBitmap);
                // Bind to the texture in OpenGL
                // Recycle the bitmap, since its data has been loaded into OpenGL.
                mBitmap.recycle();
                mBitmap = null;
                setTextureLoaded();
            } catch (Exception ex) {
                ex.printStackTrace();
                Log.e("AsyncButton", ex.toString());
            }
        }

        if (alpha == 0f) return;
        GLES20.glUseProgram(glProgram);
        GLUtils.checkGLError("glProgram");

        GLES20.glEnableVertexAttribArray(this.worldParams.mPositionParam);
        GLUtils.checkGLError("mPositionParam");

        GLES20.glEnableVertexAttribArray(this.worldParams.mTextureCoordParam);
        GLES20.glVertexAttribPointer(this.worldParams.mTextureCoordParam, 2, GLES20.GL_FLOAT, false, 4 * 2, pTexCoord);
        GLES20.glUniform1f(worldParams.mIsFloorParam, alpha);

        Matrix.multiplyMM(this.mModelView, 0, view, 0, this.mModel, 0);
        Matrix.multiplyMM(this.mModelViewProjection, 0, perspective, 0, this.mModelView, 0);
        Matrix.scaleM(this.mModelViewProjection, 0, this.scale, this.scale, 1f);

        // Set the position of the cube
        GLES20.glVertexAttribPointer(this.worldParams.mPositionParam, COORDS_PER_VERTEX, GLES20.GL_FLOAT,
                false, 0, this.rectangle);

        // Set the ModelViewProjection matrix in the shader.
        GLES20.glUniformMatrix4fv(this.worldParams.mModelViewProjectionParam, 1, false, mModelViewProjection, 0);

        GLES20.glBlendFunc(GLES20.GL_SRC_ALPHA, GLES20.GL_ONE_MINUS_SRC_ALPHA);
        GLES20.glEnable(GLES20.GL_BLEND);

        GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texture);
        GLES20.glUniform1i(worldParams.mTextureParam, 0);
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);
        GLES20.glDisableVertexAttribArray(this.worldParams.mTextureCoordParam);
        GLUtils.checkGLError("drawing button");
    }

    @Override
    public void init() {
        this.initShader(this.ctx);
        final AsyncButton instance = this;

        new Thread(new Runnable() {
            @Override
            public void run() {
                instance.mBitmap = instance.imageProvider.getImage();
            }
        }).start();


        final float[] coordsArr = new float[]{
                width, -height, 0f,
                -width, -height, 0f,
                width, height, 0f,
                -width, height, 0f
        };

        final float[] ttmp = {1.0f, 1.0f, 0.0f, 1.0f, 1.0f, 0.0f, 0.0f, 0.0f};

        this.pTexCoord = ByteBuffer.allocateDirect(8 * 4).order(ByteOrder.nativeOrder()).asFloatBuffer();
        this.pTexCoord.put(ttmp);
        this.pTexCoord.position(0);

        ByteBuffer vertices = ByteBuffer.allocateDirect(coordsArr.length * 4);
        vertices.order(ByteOrder.nativeOrder());
        this.rectangle = vertices.asFloatBuffer();
        this.rectangle.put(coordsArr);
        this.rectangle.position(0);

        this.worldParams = new WorldParams(this.glProgram);
    }

    @Override
    public void dispose() {
        int[] textures = new int[]{this.texture};
        GLES20.glDeleteTextures(1, textures, 0);
        if (mBitmap != null) {
            mBitmap.recycle();
            mBitmap = null;
        }
    }

    @Override
    public boolean isComparable() {
        return true;
    }

    @Override
    public void setVisibility(boolean visibility) {
        this.visibility = visibility;
    }

    @Override
    public void focus() {
        this.targetScale = this.scaleSpeed;
    }

    @Override
    public void unfocus() {
        if (this.targetScale != 1) {
            targetScale = 1f;
        }
    }

    public void hide() {
        targetAlpha = 0f;
        mIsEnable = false;
    }

    public void show() {
        targetAlpha = 1f;
        mIsEnable = true;
    }

    public boolean isEnable() {
        return mIsEnable;
    }

    public void setScale(float scale) {
        if (scale < 1f) return;
        this.scaleSpeed = scale;
    }

    private void initShader(Context context) {
        int vertexShader = GLUtils.loadGLShader(context, GLES20.GL_VERTEX_SHADER, R.raw.texturea_vertex);
        int gridShader = GLUtils.loadGLShader(context, GLES20.GL_FRAGMENT_SHADER, R.raw.texturea_fragment);

        this.glProgram = GLES20.glCreateProgram();
        GLES20.glAttachShader(this.glProgram, vertexShader);
        GLES20.glAttachShader(this.glProgram, gridShader);
        GLES20.glLinkProgram(this.glProgram);
    }

    public void setAlpha(float alpha) {
        this.alpha = alpha;
        targetAlpha = alpha;
    }

    @Override
    public void click() {
        if (mIsEnable) {
            super.click();
        }
    }
}

*/