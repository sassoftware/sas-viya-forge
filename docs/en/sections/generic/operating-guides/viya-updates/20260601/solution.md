## Solution overview

### Update availability
SAS ships a CronJob that regularly checks whether software updates are available for your Viya environment. This [Update Checker Report](https://go.documentation.sas.com/doc/en/itopscdc/v_076/k8sag/p1it185kd37v25n1aoybu799tpk4.htm) can be accessed once it has been [enabled](https://go.documentation.sas.com/doc/en/itopscdc/v_076/dplyml0phy0dkr/n08u2yg8tdkb4jn18u8zsi6yfv3d.htm#p09ingu4hyzgaun14w4b80koghr9). The Update Checker Report will inform you of both the availability of new software versions as well as available patch updates.

### Preparing for an update
Regardless of whether you are updating to a new version or applying a patch update, it is important to ensure your environment is ready for an update. A pre-update checklist can be found [here](https://go.documentation.sas.com/doc/en/itopscdc/default/k8sag/p1sv25bpu9fl2xn1ecj5j89dxubt.htm). In addition, a number of best practices have been documented [here](https://go.documentation.sas.com/doc/en/itopscdc/default/k8sag/p0dyk8rscirt5an1g4nd0f0gtp0c.htm). It is recommended to familiarize yourself with both of these documents before proceeding.

### Updating to a new version

The instructions for updating to a new version can be found [here](https://go.documentation.sas.com/doc/en/itopscdc/v_076/k8sag/p043aa4ghwwom6n1beyfifdgkve7.htm).

### Applying a patch update

The instructions for applying a patch update can be found [here](https://go.documentation.sas.com/doc/en/itopscdc/v_076/k8sag/p0954mgxmsddrmn1klrphsbnqasm.htm).

### After the update
Once you have applied the software update, you may want to perform a number of additional actions based on the type of update you performed.

#### New version
If you updated to a new version, you may want to run a set of regression tests on those parts of the Viya platform that are critical to your operation. Although uncommon, version updates may alter the behavior of some components that mean that some adjustments may be required. This is especially true if the last update was a while ago.
In addition, if you updated to a new version to get access to specific new functionality, you may want to test that functionality and inform users that it is now available.

#### Patch update
If you applied a patch update, you likely did this to resolve a specific issue or security vulnerability. To verify whether the patch was applied correctly, test that the issue you were experiencing or the vulnerability that you were seeing has now indeed been resolved. Extensive testing of existing functionality should not be required as patch updates do not introduce new functionality or change existing functionality.