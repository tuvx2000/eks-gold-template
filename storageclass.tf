# #############################################
# #              Storage Classes              #
# #############################################
# resource "kubernetes_annotations" "gp2" {
#   api_version = "storage.k8s.io/v1"
#   kind        = "StorageClass"
#   force       = "true"

#   metadata {
#     name = "gp2"
#   }

#   annotations = {
#     # Modify annotations to remove gp2 as default storage class still reatain the class
#     "storageclass.kubernetes.io/is-default-class" = "false"
#   }

#   depends_on = [
#     module.eks_kubernetes_addons
#   ]
# }

# resource "kubernetes_storage_class_v1" "gp3" {
#   metadata {
#     name = "gp3"

#     annotations = {
#       # Annotation to set gp3 as default storage class
#       "storageclass.kubernetes.io/is-default-class" = "true"
#     }
#   }

#   storage_provisioner    = "ebs.csi.aws.com"
#   allow_volume_expansion = true
#   reclaim_policy         = "Delete"
#   volume_binding_mode    = "WaitForFirstConsumer"

#   parameters = {
#     encrypted = true
#     fsType    = "ext4"
#     type      = "gp3"

#   }

#   depends_on = [
#     kubernetes_annotations.gp2
#   ]
# }
