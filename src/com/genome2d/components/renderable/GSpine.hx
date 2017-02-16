/**
 * Created with IntelliJ IDEA.
 * User: Peter "sHTiF" Stefcek
 * Date: 17.5.2013
 * Time: 14:03
 * To change this template use File | Settings | File Templates.
 */
package com.genome2d.components.renderable;

import com.genome2d.geom.GMatrix;
import com.genome2d.context.GBlendMode;
import com.genome2d.Genome2D;
import com.genome2d.components.GComponent;
import com.genome2d.components.renderable.IGRenderable;
import com.genome2d.context.GCamera;
import com.genome2d.context.IGContext;
import com.genome2d.input.GMouseInput;
import com.genome2d.spine.GAtlasAttachmentLoader;
import com.genome2d.spine.GAtlasTextureLoader;
import com.genome2d.textures.GTexture;
import com.genome2d.geom.GRectangle;

import spinehaxe.Bone;
import spinehaxe.Skeleton;
import spinehaxe.SkeletonData;
import spinehaxe.SkeletonJson;
import spinehaxe.Slot;
import spinehaxe.animation.AnimationState;
import spinehaxe.animation.AnimationStateData;
import spinehaxe.atlas.Atlas;
import spinehaxe.attachments.RegionAttachment;

class GSpine extends GComponent implements IGRenderable
{
    private var _attachmentLoader:GAtlasAttachmentLoader;
    private var _atlasLoader:GAtlasTextureLoader;

    private var _states:Map<String,AnimationState>;
    private var _activeState:AnimationState;

    private var _skeletons:Map<String,Skeleton>;
    private var _activeSkeleton:Skeleton;

    override public function init():Void {
        _skeletons = new Map<String,Skeleton>();
        _states = new Map<String,AnimationState>();

        node.core.onUpdate.add(update);
    }

    public function setup(p_atlas:String, p_texture:GTexture, p_defaultAnim:String = "stand"):Void {
        _atlasLoader = new GAtlasTextureLoader(p_texture);
        var atlas:Atlas = new Atlas(p_atlas, _atlasLoader);
        _attachmentLoader = new GAtlasAttachmentLoader(atlas);
    }

    public function setAttachment(p_slotName:String, p_attachmentName:String):Void {
        for (skeleton in _skeletons) {
            skeleton.setAttachment(p_slotName, p_attachmentName);
        }
    }

    public function setSkin(p_skinName:String):Void {
        for (skeleton in _skeletons) {
            skeleton.skinName = p_skinName;
        }
    }

    public function addSkeleton(p_id:String, p_json:String):Void {
        var json:SkeletonJson = new SkeletonJson(_attachmentLoader);
        var skeletonData:SkeletonData = json.readSkeletonData(p_json);
        var skeleton:Skeleton = new Skeleton(skeletonData);
        skeleton.updateWorldTransform();
        _skeletons.set(p_id, skeleton);

        var stateData:AnimationStateData = new AnimationStateData(skeletonData);
        var state:AnimationState = new AnimationState(stateData);
        _states.set(p_id, state);
    }

    public function setActiveSkeleton(p_skeletonId:String, p_anim:String):Void {
        if (_skeletons.get(p_skeletonId) != null && _activeSkeleton != _skeletons.get(p_skeletonId)) {
            _activeSkeleton = _skeletons.get(p_skeletonId);
            _activeState = _states.get(p_skeletonId);
            _activeState.setAnimationByName(0, p_anim, true);
            _activeState.update(Math.random());
        }
    }

    public function update(p_deltaTime:Float):Void {
        if (_activeState != null) {
            _activeState.update(p_deltaTime / 1000);
            _activeState.apply(_activeSkeleton);
            _activeSkeleton.updateWorldTransform();
        }
    }

    public function render(p_camera:GCamera, p_useMatrix:Bool):Void {
        var matrix:GMatrix = new GMatrix();
        var context:IGContext = Genome2D.getInstance().getContext();

        if (_activeSkeleton != null) {
            var drawOrder:Array<Slot> = _activeSkeleton.drawOrder;

            for (i in 0...drawOrder.length) {
                var slot:Slot = drawOrder[i];
                var regionAttachment:RegionAttachment = cast slot.attachment;
                if (regionAttachment != null) {
                    var bone:Bone = slot.bone;

                    var texture:GTexture = cast regionAttachment.rendererObject;
                    matrix.identity();
                    matrix.scale(regionAttachment.scaleX,regionAttachment.scaleY);
                    matrix.rotate(-regionAttachment.rotation * Math.PI/180 + (texture.rotate?Math.PI / 2:0));
                    matrix.scale(bone.worldScaleX, bone.worldScaleY);
                    matrix.rotate(bone.worldRotationX * Math.PI / 180);
                    matrix.translate(node.g2d_worldX + bone.worldX + regionAttachment.x * bone.a + regionAttachment.y * bone.b, node.g2d_worldY + bone.worldY + regionAttachment.x * bone.c + regionAttachment.y * bone.d);

                    context.drawMatrix(texture, GBlendMode.NORMAL, matrix.a, matrix.b, matrix.c, matrix.d, matrix.tx, matrix.ty);
                }
            }
        }
    }
	
    public function getBounds(p_bounds:GRectangle = null):GRectangle {
        if (p_bounds != null) p_bounds.setTo(-60, -60, 100, 60);
        else p_bounds = new GRectangle(-60,-60,100,60);
        return p_bounds;
    }

    public function captureMouseInput(p_input:GMouseInput):Void {
        p_input.captured = p_input.captured || hitTest(p_input.localX, p_input.localY);
    }

    public function hitTest(p_x:Float,p_y:Float):Bool {
        var hit:Bool = false;
        var width:Int = 60;
        var height:Int = 70;

        p_x = p_x / width + .5;
        p_y = p_y / height + .95;

        hit = (p_x >= 0 && p_x <= 1 && p_y >= 0 && p_y <= 1);

        return hit;
    }

    override public function dispose():Void {
        node.core.onUpdate.remove(update);

        // pridal som if na _atlasLoader, lebo mi to tu padlo, ked som v tutorial bani talkol npc lindy a pocas miznutia
        // som sa prepol do campu
        if (_atlasLoader != null) {
            _atlasLoader.dispose();
        }
    }
}