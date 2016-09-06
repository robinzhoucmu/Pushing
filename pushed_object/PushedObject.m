classdef PushedObject
   properties
      % Limit surface related.
      ls_coeffs
      ls_type
      % Pressure related.
      support_pts
      pressure_weights
      % Coefficient of contact friction between pusher and the object.
      %mu_contact
      % Shape and geometry related. 
      shape_type
      shape_metatype
      shape_vertices % object coordinate frame.
      shape_parameters % radius of circle, two axis length of ellipse, etc.
      pho % radius of gyration.
      
      % Pose related. object coordinate frame w.r.t the world frame.
      pose %3*1: [x;y;theta]
      cur_shape_vertices % shape vertices in world frame.
      
   end
   methods
       
      function [pt_closest, dist] = FindClosestPointAndDistanceWorldFrame(obj, pt)
         % Input: pt is a 2*1 column vector. 
         % Output: distance and the projected/closest point (2*1) on the object.
         dist = 0; pt_closest = [0;0];
         if strcmp(obj.shape_metatype, 'polygon')
             [tip_proj, dist] = projPointOnPolygon(pt', obj.cur_shape_vertices);
             pt_closest = polygonPoint(obj.cur_shape_vertices, tip_proj);
             pt_closest = pt_closest';
             
         elseif strcmp(obj.shape_metatype, 'circle')
             dist = norm(pt - obj.pose(1:2));
             pt_closest = obj.pose(1:2) + ...
                 obj.shape_parameters.radius * (pt - obj.pose(1:2)) / dist;
             
         elseif strcmp(obj.shape_metatype, 'ellipse')
         else
            fprintf('Shape meta type not supported%s\n', obj.shape_metatype);
         end
      end
      
      function [vec_local] = GetVectorInLocalFrame(obj, vec) 
            % Input: a column vector 2*1 in world frame.
            % Output: rotated to local frame.
            theta = obj.pose(3);
            R = [cos(theta) sin(theta); -sin(theta) cos(theta)];
            vec_local = R' * vec;
      end
      function [flag_contact] = GetRoundFingerContactInfo()
      end
          
      function [twist_local, wrench_load_local, contact_mode] = ComputeVelGivenPointRoundFingerPush(obj, ...
              pt_global, vel_global, normal_global, mu)
        % Input: 
        % contact point on the object (pt 2*1), pushing velocity (vel 2*1)
        % and outward normal (2*1, pointing from object to pusher) in world frame;  
        % mu: coefficient of friction. 
        % Note: Ensure that the point is actually in contact before using
        % this function. It does not check point on boundary.
        % Output: 
        % Body twist, friction wrench load (local frame) on the 1 level set of
        % limit surface and contact mode ('separation', 'sticking', 'leftsliding', 'rightsliding' ). 
        % Note that the third component is unnormalized,
        % i.e, F(3) is torque in NewtonMeters and V(3) is radian/second. 
        % If the velocity of pushing is breaking contact, then we return 
        % all zero 3*1 vector. 
        
        % Change vel, pt and normal to local frame first. 
        vel_local = obj.GetVectorInLocalFrame(vel_global);        
        % Compute the point of contact.
        pt_local = obj.GetVectorInLocalFrame(pt_global);
        normal_local = obj.GetVectorInLocalFrame(normal_global);
        
        [wrench_load_local, twist_local, contact_mode] = ComputeVelGivenSingleContactPtPush(vel_local, pt_local, ...
            normal_local, mu, obj.pho, obj.ls_coeffs, obj.ls_type);
        % Un-normalize the third components of F and V.
        wrench_load_local(3) = wrench_load_local(3) * obj.pho;
        twist_local(3) = twist_local(3) / obj.pho;  
        
      end
      
   end
end