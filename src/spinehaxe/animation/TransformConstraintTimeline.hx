/******************************************************************************
 * Spine Runtimes Software License v2.5
 *
 * Copyright (c) 2013-2016, Esoteric Software
 * All rights reserved.
 *
 * You are granted a perpetual, non-exclusive, non-sublicensable, and
 * non-transferable license to use, install, execute, and perform the Spine
 * Runtimes software and derivative works solely for personal or internal
 * use. Without the written permission of Esoteric Software (see Section 2 of
 * the Spine Software License Agreement), you may not (a) modify, translate,
 * adapt, or develop new applications using the Spine Runtimes or otherwise
 * create derivative works or improvements of the Spine Runtimes or (b) remove,
 * delete, alter, or obscure any trademarks or any copyright, trademark, patent,
 * or other intellectual property or proprietary rights notices on or in the
 * Software, including any copy thereof. Redistributions in binary or source
 * form must include this license and terms.
 *
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ESOTERIC SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES, BUSINESS INTERRUPTION, OR LOSS OF
 * USE, DATA, OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 * IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

package spinehaxe.animation;

import haxe.ds.Vector;
import spinehaxe.TransformConstraintData;
import spinehaxe.Event;
import spinehaxe.Skeleton;
import spinehaxe.TransformConstraint;

class TransformConstraintTimeline extends CurveTimeline {
	static public inline var ENTRIES:Int = 5;
	static inline var PREV_TIME:Int = -5;
	static inline var PREV_ROTATE:Int = -4;
	static inline var PREV_TRANSLATE:Int = -3;
	static inline var PREV_SCALE:Int = -2;
	static inline var PREV_SHEAR:Int = -1;
	static inline var ROTATE:Int = 1;
	static inline var TRANSLATE:Int = 2;
	static inline var SCALE:Int = 3;
	static inline var SHEAR:Int = 4;

	public var transformConstraintIndex:Int;
	public var frames:Vector<Float>; // time, rotate mix, translate mix, scale mix, shear mix, ...

	public function new(frameCount:Int) {
		super(frameCount);
		frames = ArrayUtils.allocFloat(frameCount * ENTRIES);
	}

	override public function getPropertyId():Int {
		return (TimelineType.transformConstraint << 24) + transformConstraintIndex;
	}

	/** Sets the time and mixes of the specified keyframe. */
	public function setFrame(frameIndex:Int, time:Float, rotateMix:Float, translateMix:Float, scaleMix:Float, shearMix:Float):Void {
		frameIndex *= ENTRIES;
		frames[frameIndex] = time;
		frames[frameIndex + ROTATE] = rotateMix;
		frames[frameIndex + TRANSLATE] = translateMix;
		frames[frameIndex + SCALE] = scaleMix;
		frames[frameIndex + SHEAR] = shearMix;
	}

	override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, firedEvents:Array<Event>, alpha:Float, setupPose:Bool, mixingOut:Bool):Void {
		var constraint:TransformConstraint  = skeleton.transformConstraints[transformConstraintIndex];
		var data:TransformConstraintData;
		if (time < frames[0]) {
			if (setupPose) {
				data = constraint.data;
				constraint.rotateMix = constraint.data.rotateMix;
				constraint.translateMix = constraint.data.translateMix;
				constraint.scaleMix = constraint.data.scaleMix;
				constraint.shearMix = constraint.data.shearMix;
			}
			return;
		}

		var rotate:Float, translate:Float, scale:Float, shear:Float;
		if (time >= frames[frames.length - ENTRIES]) { // Time is after last frame.
			var i:Int = frames.length;
			rotate = frames[i + PREV_ROTATE];
			translate = frames[i + PREV_TRANSLATE];
			scale = frames[i + PREV_SCALE];
			shear = frames[i + PREV_SHEAR];
		} else {
			// Interpolate between the previous frame and the current frame.
			var frame:Int = Animation.binarySearch(frames, time, ENTRIES);
			rotate = frames[frame + PREV_ROTATE];
			translate = frames[frame + PREV_TRANSLATE];
			scale = frames[frame + PREV_SCALE];
			shear = frames[frame + PREV_SHEAR];
			var frameTime:Float = frames[frame];
			var percent:Float = getCurvePercent(Std.int(frame / ENTRIES - 1),
				1 - (time - frameTime) / (frames[frame + PREV_TIME] - frameTime));

			rotate += (frames[frame + ROTATE] - rotate) * percent;
			translate += (frames[frame + TRANSLATE] - translate) * percent;
			scale += (frames[frame + SCALE] - scale) * percent;
			shear += (frames[frame + SHEAR] - shear) * percent;
		}
		if (setupPose) {
			data = constraint.data;
			constraint.rotateMix = data.rotateMix + (rotate - data.rotateMix) * alpha;
			constraint.translateMix = data.translateMix + (translate - data.translateMix) * alpha;
			constraint.scaleMix = data.scaleMix + (scale - data.scaleMix) * alpha;
			constraint.shearMix = data.shearMix + (shear - data.shearMix) * alpha;
		} else {
			constraint.rotateMix += (rotate - constraint.rotateMix) * alpha;
			constraint.translateMix += (translate - constraint.translateMix) * alpha;
			constraint.scaleMix += (scale - constraint.scaleMix) * alpha;
			constraint.shearMix += (shear - constraint.shearMix) * alpha;
		}
	}
}
