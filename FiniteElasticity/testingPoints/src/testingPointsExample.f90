!> \file
!> \author Chris Bradley
!> \brief This is an example program to solve a finite elasticity equation using openCMISS calls.
!>
!> \section LICENSE
!>
!> Version: MPL 1.1/GPL 2.0/LGPL 2.1
!>
!> The contents of this file are subject to the Mozilla Public License
!> Version 1.1 (the "License"); you may not use this file except in
!> compliance with the License. You may obtain a copy of the License at
!> http://www.mozilla.org/MPL/
!>
!> Software distributed under the License is distributed on an "AS IS"
!> basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
!> License for the specific language governing rights and limitations
!> under the License.
!>
!> The Original Code is openCMISS
!>
!> The Initial Developer of the Original Code is University of Auckland,
!> Auckland, New Zealand and University of Oxford, Oxford, United
!> Kingdom. Portions created by the University of Auckland and University
!> of Oxford are Copyright (C) 2007 by the University of Auckland and
!> the University of Oxford. All Rights Reserved.
!>
!> Contributor(s): Jack Lee
!>
!> Alternatively, the contents of this file may be used under the terms of
!> either the GNU General Public License Version 2 or later (the "GPL"), or
!> the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
!> in which case the provisions of the GPL or the LGPL are applicable instead
!> of those above. If you wish to allow use of your version of this file only
!> under the terms of either the GPL or the LGPL, and not to allow others to
!> use your version of this file under the terms of the MPL, indicate your
!> decision by deleting the provisions above and replace them with the notice
!> and other provisions required by the GPL or the LGPL. If you do not delete
!> the provisions above, a recipient may use your version of this file under
!> the terms of any one of the MPL, the GPL or the LGPL.
!>

!> \example FiniteElasticity/UniAxialExtension/src/UniAxialExtensionExample.f90
!! Example program to solve a finite elasticity equation using openCMISS calls.
!! \par Latest Builds:
!! \li <a href='http://autotest.bioeng.auckland.ac.nz/opencmiss-build/logs_x86_64-linux/FiniteElasticity/UniAxialExtension/build-intel'>Linux Intel Build</a>
!! \li <a href='http://autotest.bioeng.auckland.ac.nz/opencmiss-build/logs_x86_64-linux/FiniteElasticity/UniAxialExtension/build-gnu'>Linux GNU Build</a>
!<

!> Main program
PROGRAM TESTINGPOINTSEXAMPLE

  USE OPENCMISS
  USE MPI

#ifdef WIN32
  USE IFQWIN
#endif

  IMPLICIT NONE

  !Test program parameters

  !Command line arguments
  CHARACTER(LEN=256) :: ARG_DIM, ARG_ELEM, ARG_BASIS_1,ARG_BASIS_2, ARG_LEVEL, ARG

  !\todo: don't hard code, read in + default
  REAL(CMISSDP), PARAMETER :: INNER_PRESSURE=0.1_CMISSDP !Positive is compressive
  REAL(CMISSDP), PARAMETER :: OUTER_PRESSURE=0.0_CMISSDP !Positive is compressive
  REAL(CMISSDP), PARAMETER :: LAMBDA=1.0_CMISSDP
  REAL(CMISSDP), PARAMETER :: TSI=0.0_CMISSDP    !Not yet working. Leave at 0
  REAL(CMISSDP), PARAMETER :: INNER_RAD=1.0_CMISSDP
  REAL(CMISSDP), PARAMETER :: OUTER_RAD=1.2_CMISSDP
  REAL(CMISSDP), PARAMETER :: HEIGHT=2.0_CMISSDP
  REAL(CMISSDP), PARAMETER :: C1=2.0_CMISSDP
  REAL(CMISSDP), PARAMETER :: C2=6.0_CMISSDP
  INTEGER(CMISSIntg), PARAMETER ::   NumberGlobalXElements=1 !\todo: don't hardcode
  INTEGER(CMISSIntg), PARAMETER ::   NumberGlobalYElements=4
  INTEGER(CMISSIntg), PARAMETER ::   NumberGlobalZElements=1

  INTEGER(CMISSIntg), PARAMETER :: CoordinateSystemUserNumber=1
  INTEGER(CMISSIntg), PARAMETER :: NumberOfSpatialCoordinates=3
  INTEGER(CMISSIntg), PARAMETER :: RegionUserNumber=1
  INTEGER(CMISSIntg), PARAMETER :: LinearBasisUserNumber=1
  INTEGER(CMISSIntg), PARAMETER :: QuadraticBasisUserNumber=2
  INTEGER(CMISSIntg), PARAMETER :: CubicBasisUserNumber=3
  INTEGER(CMISSIntg), PARAMETER :: MeshUserNumber=1
  INTEGER(CMISSIntg), PARAMETER :: GeneratedMeshUserNumber=2
  INTEGER(CMISSIntg), PARAMETER :: DecompositionUserNumber=1

  INTEGER(CMISSIntg), PARAMETER :: NumberOfMeshDimensions=3
  INTEGER(CMISSIntg), PARAMETER :: NumberOfXiCoordinates=3
  INTEGER(CMISSIntg), PARAMETER :: NumberOfMeshComponents=2
  INTEGER(CMISSIntg), PARAMETER :: DisplacementMeshComponentNumber=1
  INTEGER(CMISSIntg), PARAMETER :: PressureMeshComponentNumber=2

  INTEGER(CMISSIntg), PARAMETER :: FieldGeometryUserNumber=1
  INTEGER(CMISSIntg), PARAMETER :: FieldGeometryNumberOfVariables=1
  INTEGER(CMISSIntg), PARAMETER :: FieldGeometryNumberOfComponents=3

  INTEGER(CMISSIntg), PARAMETER :: FieldFibreUserNumber=2
  INTEGER(CMISSIntg), PARAMETER :: FieldFibreNumberOfVariables=1
  INTEGER(CMISSIntg), PARAMETER :: FieldFibreNumberOfComponents=3

  INTEGER(CMISSIntg), PARAMETER :: FieldMaterialUserNumber=3
  INTEGER(CMISSIntg), PARAMETER :: FieldMaterialNumberOfVariables=1
  INTEGER(CMISSIntg), PARAMETER :: FieldMaterialNumberOfComponents=2

  INTEGER(CMISSIntg), PARAMETER :: FieldDependentUserNumber=4
  INTEGER(CMISSIntg), PARAMETER :: FieldDependentNumberOfVariables=2
  INTEGER(CMISSIntg), PARAMETER :: FieldDependentNumberOfComponents=4

  INTEGER(CMISSIntg), PARAMETER :: FieldAnalyticUserNumber=1337

  INTEGER(CMISSIntg), PARAMETER :: EquationSetUserNumber=1
  INTEGER(CMISSIntg), PARAMETER :: EquationsSetFieldUserNumber=5
  INTEGER(CMISSIntg), PARAMETER :: ProblemUserNumber=1

  !Program types


  !Program variables
  INTEGER(CMISSIntg) :: MPI_IERROR
  INTEGER(CMISSIntg) :: EquationsSetIndex  
  INTEGER(CMISSIntg) :: NumberOfComputationalNodes,NumberOfDomains,ComputationalNodeNumber

  !CMISS variables

  TYPE(CMISSBasisType) :: CubicBasis, QuadraticBasis, LinearBasis, Bases(2)
  TYPE(CMISSBoundaryConditionsType) :: BoundaryConditions
  TYPE(CMISSCoordinateSystemType) :: CoordinateSystem, WorldCoordinateSystem
  TYPE(CMISSMeshType) :: Mesh
  TYPE(CMISSGeneratedMeshType) :: GeneratedMesh
  TYPE(CMISSDecompositionType) :: Decomposition
  TYPE(CMISSEquationsType) :: Equations
  TYPE(CMISSEquationsSetType) :: EquationsSet
  TYPE(CMISSFieldType) :: GeometricField,FibreField,MaterialField
  TYPE(CMISSFieldType) :: DependentField,EquationsSetField,AnalyticField
  TYPE(CMISSFieldsType) :: Fields
  TYPE(CMISSProblemType) :: Problem
  TYPE(CMISSRegionType) :: Region,WorldRegion
  TYPE(CMISSSolverType) :: Solver,LinearSolver
  TYPE(CMISSSolverEquationsType) :: SolverEquations
  !TYPE(CMISSNodesType) :: Nodes
  !TYPE(CMISSMeshElementsType) :: QuadraticElements,LinearElements
  TYPE(CMISSControlLoopType) :: ControlLoop

  !Other variables
  INTEGER(CMISSIntg) :: NN
  LOGICAL :: X_FIXED,Y_FIXED, X_OKAY,Y_OKAY

  INTEGER(CMISSIntg),ALLOCATABLE :: TopSurfaceNodes(:)
  INTEGER(CMISSIntg),ALLOCATABLE :: BottomSurfaceNodes(:)
  INTEGER(CMISSIntg),ALLOCATABLE :: InnerSurfaceNodes(:)
  INTEGER(CMISSIntg),ALLOCATABLE :: OuterSurfaceNodes(:)
  INTEGER(CMISSIntg) :: TopNormalXi,BottomNormalXi,InnerNormalXi,OuterNormalXi
  REAL(CMISSDP) :: xValue,yValue, InitialPressure,deformedHeight

#ifdef WIN32
  !Quickwin type
  LOGICAL :: QUICKWIN_STATUS=.FALSE.
  TYPE(WINDOWCONFIG) :: QUICKWIN_WINDOW_CONFIG
#endif

  !Generic CMISS variables
  INTEGER(CMISSIntg) :: Err

#ifdef WIN32
  !Initialise QuickWin
  QUICKWIN_WINDOW_CONFIG%TITLE="General Output" !Window title
  QUICKWIN_WINDOW_CONFIG%NUMTEXTROWS=-1 !Max possible number of rows
  QUICKWIN_WINDOW_CONFIG%MODE=QWIN$SCROLLDOWN
  !Set the window parameters
  QUICKWIN_STATUS=SETWINDOWCONFIG(QUICKWIN_WINDOW_CONFIG)
  !If attempt fails set with system estimated values
  IF(.NOT.QUICKWIN_STATUS) QUICKWIN_STATUS=SETWINDOWCONFIG(QUICKWIN_WINDOW_CONFIG)
#endif

  !Parse command-line arguments: it's a bit ugly at the mo
  IF(IARGC()==0) THEN
    CALL GETARG(0,ARG)
    WRITE(*,*) "Syntax:"
    WRITE(*,*) TRIM(ARG)//" -DIM=2D/3D  -ELEM=HEX/TET  -BASIS_1=CUBIC/QUADRATIC  -BASIS_2=QUADRATIC/LINEAR  -LEVEL=1/2/3"
    STOP
  ENDIF

  CALL GET_ARGUMENT("DIM",ARG_DIM)
  IF(TRIM(ARG_DIM)/="3D") THEN
    WRITE(*,*) "ONLY 3D PROBLEMS ARE IN THE TESTING MATRIX."
    STOP
  ENDIF

  CALL GET_ARGUMENT("ELEM",ARG_ELEM)
    if (TRIM(ARG_ELEM)=="TET") then
      write(*,*) "tets are not yet implemented."
      stop
    endif
  IF(.NOT.(TRIM(ARG_ELEM)=="TET".OR.TRIM(ARG_ELEM)=="HEX")) THEN
    WRITE(*,*) "ONLY TET OR HEX ELEMENT TYPES ARE PERMITTED."
    STOP
  ENDIF

  CALL GET_ARGUMENT("BASIS_1",ARG_BASIS_1)
  IF(.NOT.(TRIM(ARG_BASIS_1)=="CUBIC".OR.TRIM(ARG_BASIS_1)=="QUADRATIC")) THEN
    IF(TRIM(ARG_BASIS_1)=="HERMITE") THEN
      WRITE(*,*) "CUBIC HERMITE BASIS IS NOT YET IMPLEMENTED."
      STOP
    ELSE
      WRITE(*,*) "ONLY CUBIC AND QUADRATIC BASIS TYPE ARE ALLOWED FOR DISPLACEMENT VARIABLES AT THE MOMENT."
      STOP
    ENDIF
  ENDIF

  CALL GET_ARGUMENT("BASIS_2",ARG_BASIS_2)
  IF(.NOT.(TRIM(ARG_BASIS_2)=="QUADRATIC".OR.TRIM(ARG_BASIS_2)=="LINEAR")) THEN
    WRITE(*,*) "ONLY QUADRATIC OR LINEAR BASIS TYPES ARE ALLOWED FOR PRESSURE VARIABLE."
    STOP
  ENDIF

  CALL GET_ARGUMENT("LEVEL",ARG_LEVEL)
  IF(.NOT.(TRIM(ARG_LEVEL)=="1".OR.TRIM(ARG_LEVEL)=="2".OR.TRIM(ARG_LEVEL)=="3")) THEN
    WRITE(*,*) "INVALID TESTING LEVEL"
    STOP
  ENDIF

  !Intialise cmiss
  CALL CMISSInitialise(WorldCoordinateSystem,WorldRegion,Err)

  CALL CMISSErrorHandlingModeSet(CMISSTrapError,Err)

  WRITE(*,'(A)') "Program starting."

  !Set all diganostic levels on for testing
  CALL CMISSDiagnosticsSetOn(CMISSFromDiagType,(/1,2,3,4,5/),"Diagnostics",(/"PROBLEM_FINITEARG_ELEMENT_CALCULATE"/),Err)

  !Get the number of computational nodes and this computational node number
  CALL CMISSComputationalNumberOfNodesGet(NumberOfComputationalNodes,Err)
  CALL CMISSComputationalNodeNumberGet(ComputationalNodeNumber,Err)

  write(*,*) "NumberOfDomains=",NumberOfComputationalNodes
  NumberOfDomains=NumberOfComputationalNodes !1

  !Broadcast the number of elements in the X,Y and Z directions and the number of partitions to the other computational nodes
  CALL MPI_BCAST(NumberOfDomains,1,MPI_INTEGER,0,MPI_COMM_WORLD,MPI_IERROR)
  
  !Create a CS - default is 3D rectangular cartesian CS with 0,0,0 as origin
  CALL CMISSCoordinateSystemTypeInitialise(CoordinateSystem,Err)
  CALL CMISSCoordinateSystemCreateStart(CoordinateSystemUserNumber,CoordinateSystem,Err)
  CALL CMISSCoordinateSystemTypeSet(CoordinateSystem,CMISSCoordinateRectangularCartesianType,Err)
  CALL CMISSCoordinateSystemDimensionSet(CoordinateSystem,NumberOfSpatialCoordinates,Err)
  CALL CMISSCoordinateSystemOriginSet(CoordinateSystem,(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/),Err)
  CALL CMISSCoordinateSystemCreateFinish(CoordinateSystem,Err)

  !Create a region and assign the CS to the region
  CALL CMISSRegionTypeInitialise(Region,Err)
  CALL CMISSRegionCreateStart(RegionUserNumber,WorldRegion,Region,Err)
  CALL CMISSRegionCoordinateSystemSet(Region,CoordinateSystem,Err)
  CALL CMISSRegionCreateFinish(Region,Err)

  !Define basis functions - just define all types here, some not used
  CALL CMISSBasisTypeInitialise(LinearBasis,Err)
  CALL CMISSBasisCreateStart(LinearBasisUserNumber,LinearBasis,Err)
  CALL CMISSBasisQuadratureNumberOfGaussXiSet(LinearBasis, &
    & (/CMISSBasisHighQuadratureScheme,CMISSBasisHighQuadratureScheme,CMISSBasisHighQuadratureScheme/),Err)
  CALL CMISSBasisQuadratureLocalFaceGaussEvaluateSet(LinearBasis,.true.,Err) !Have to do this (unused) due to field_interp setup
  CALL CMISSBasisCreateFinish(LinearBasis,Err)

  CALL CMISSBasisTypeInitialise(QuadraticBasis,Err)
  CALL CMISSBasisCreateStart(QuadraticBasisUserNumber,QuadraticBasis,Err)
  CALL CMISSBasisInterpolationXiSet(QuadraticBasis,(/CMISSBasisQuadraticLagrangeInterpolation, &
    & CMISSBasisQuadraticLagrangeInterpolation,CMISSBasisQuadraticLagrangeInterpolation/),Err)
  CALL CMISSBasisQuadratureNumberOfGaussXiSet(QuadraticBasis, &
    & (/CMISSBasisHighQuadratureScheme,CMISSBasisHighQuadratureScheme,CMISSBasisHighQuadratureScheme/),Err)
  CALL CMISSBasisQuadratureLocalFaceGaussEvaluateSet(QuadraticBasis,.true.,Err) !Enable 3D interpolation on faces
  CALL CMISSBasisCreateFinish(QuadraticBasis,Err)

  CALL CMISSBasisTypeInitialise(CubicBasis,Err)
  CALL CMISSBasisCreateStart(CubicBasisUserNumber,CubicBasis,Err)
  CALL CMISSBasisInterpolationXiSet(CubicBasis,(/CMISSBasisCubicLagrangeInterpolation, &
    & CMISSBasisCubicLagrangeInterpolation,CMISSBasisCubicLagrangeInterpolation/),Err)
  CALL CMISSBasisQuadratureNumberOfGaussXiSet(CubicBasis, &
    & (/CMISSBasisHighQuadratureScheme,CMISSBasisHighQuadratureScheme,CMISSBasisHighQuadratureScheme/),Err)
  CALL CMISSBasisQuadratureLocalFaceGaussEvaluateSet(CubicBasis,.true.,Err) !Enable 3D interpolation on faces
  CALL CMISSBasisCreateFinish(CubicBasis,Err)

  !Which of these bases are we using?
  SELECT CASE (ARG_BASIS_1)
  CASE ("CUBIC")
    Bases(1)=CubicBasis
  CASE ("QUADRATIC")
    Bases(1)=QuadraticBasis
  END SELECT

  SELECT CASE (ARG_BASIS_2)
  CASE ("QUADRATIC")
    Bases(2)=QuadraticBasis
  CASE ("LINEAR")
    Bases(2)=LinearBasis
  END SELECT

  !Start the creation of a generated cylinder mesh
  CALL CMISSGeneratedMeshTypeInitialise(GeneratedMesh,Err)
  CALL CMISSGeneratedMeshCreateStart(GeneratedMeshUserNumber,Region,GeneratedMesh,Err)
  !Set up an cylinder mesh
  CALL CMISSGeneratedMeshTypeSet(GeneratedMesh,CMISSGeneratedMeshCylinderMeshType,Err)
  !Set the bases on the generated mesh
  CALL CMISSGeneratedMeshBasisSet(GeneratedMesh,Bases,Err)
  !Define the mesh on the region
  CALL CMISSGeneratedMeshExtentSet(GeneratedMesh,(/INNER_RAD, OUTER_RAD, HEIGHT/),Err)
  CALL CMISSGeneratedMeshNumberOfElementsSet(GeneratedMesh,(/NumberGlobalXElements,NumberGlobalYElements, &
    & NumberGlobalZElements/),Err)
  
  !Finish the creation of generated mesh in the region
  CALL CMISSMeshTypeInitialise(Mesh,Err)
  CALL CMISSGeneratedMeshCreateFinish(GeneratedMesh,MeshUserNumber,Mesh,Err)

  !Create a decomposition
  CALL CMISSRandomSeedsSet(0_CMISSIntg,Err) !To keep the automatic decomposition same each time
  CALL CMISSDecompositionTypeInitialise(Decomposition,Err)
  CALL CMISSDecompositionCreateStart(DecompositionUserNumber,Mesh,Decomposition,Err)
  !Automatic decomposition
  CALL CMISSDecompositionTypeSet(Decomposition,CMISSDecompositionCalculatedType,Err)
  CALL CMISSDecompositionNumberOfDomainsSet(Decomposition,NumberOfDomains,Err)
  !Manual decomposition
!   IF(NumberOfDomains>1) THEN
!     CALL CMISSDecompositionTypeSet(Decomposition,CMISSDecompositionUserDefinedType,Err)
!     !Set all elements but last one to first domain
!     CALL CMISSMeshNumberOfElementsGet(Mesh,NE,Err)
!     do E=1,NE/2
!       CALL CMISSDecompositionElementDomainSet(Decomposition,E,0,Err)
!     enddo
!     do E=NE/2+1,NE
!       CALL CMISSDecompositionElementDomainSet(Decomposition,E,1,Err)
!     enddo
!     CALL CMISSDecompositionNumberOfDomainsSet(Decomposition,NumberOfDomains,Err)
!   ENDIF
  CALL CMISSDecompositionCalculateFacesSet(Decomposition,.TRUE.,Err)
  CALL CMISSDecompositionCreateFinish(Decomposition,Err)

  !Create a field to put the geometry (default is geometry)
  CALL CMISSFieldTypeInitialise(GeometricField,Err)
  CALL CMISSFieldCreateStart(FieldGeometryUserNumber,Region,GeometricField,Err)
  CALL CMISSFieldMeshDecompositionSet(GeometricField,Decomposition,Err)
  CALL CMISSFieldTypeSet(GeometricField,CMISSFieldGeometricType,Err)  
  CALL CMISSFieldNumberOfVariablesSet(GeometricField,FieldGeometryNumberOfVariables,Err)
  CALL CMISSFieldNumberOfComponentsSet(GeometricField,CMISSFieldUVariableType,FieldGeometryNumberOfComponents,Err)  
  CALL CMISSFieldComponentMeshComponentSet(GeometricField,CMISSFieldUVariableType,1,DisplacementMeshComponentNumber,Err)
  CALL CMISSFieldComponentMeshComponentSet(GeometricField,CMISSFieldUVariableType,2,DisplacementMeshComponentNumber,Err)
  CALL CMISSFieldComponentMeshComponentSet(GeometricField,CMISSFieldUVariableType,3,DisplacementMeshComponentNumber,Err)
  CALL CMISSFieldCreateFinish(GeometricField,Err)

  !Update the geometric field parameters
  CALL CMISSGeneratedMeshGeometricParametersCalculate(GeometricField,GeneratedMesh,Err)

  !Create a fibre field and attach it to the geometric field  
  CALL CMISSFieldTypeInitialise(FibreField,Err)
  CALL CMISSFieldCreateStart(FieldFibreUserNumber,Region,FibreField,Err)
  CALL CMISSFieldTypeSet(FibreField,CMISSFieldFibreType,Err)
  CALL CMISSFieldMeshDecompositionSet(FibreField,Decomposition,Err)        
  CALL CMISSFieldGeometricFieldSet(FibreField,GeometricField,Err)
  CALL CMISSFieldNumberOfVariablesSet(FibreField,FieldFibreNumberOfVariables,Err)
  CALL CMISSFieldNumberOfComponentsSet(FibreField,CMISSFieldUVariableType,FieldFibreNumberOfComponents,Err)  
  CALL CMISSFieldComponentMeshComponentSet(FibreField,CMISSFieldUVariableType,1,PressureMeshComponentNumber,Err)
  CALL CMISSFieldComponentMeshComponentSet(FibreField,CMISSFieldUVariableType,2,PressureMeshComponentNumber,Err)
  CALL CMISSFieldComponentMeshComponentSet(FibreField,CMISSFieldUVariableType,3,PressureMeshComponentNumber,Err)
  CALL CMISSFieldCreateFinish(FibreField,Err)

  !Create a material field and attach it to the geometric field  
  CALL CMISSFieldTypeInitialise(MaterialField,Err)
  CALL CMISSFieldCreateStart(FieldMaterialUserNumber,Region,MaterialField,Err)
  CALL CMISSFieldTypeSet(MaterialField,CMISSFieldMaterialType,Err)
  CALL CMISSFieldMeshDecompositionSet(MaterialField,Decomposition,Err)        
  CALL CMISSFieldGeometricFieldSet(MaterialField,GeometricField,Err)
  CALL CMISSFieldNumberOfVariablesSet(MaterialField,FieldMaterialNumberOfVariables,Err)
  CALL CMISSFieldNumberOfComponentsSet(MaterialField,CMISSFieldUVariableType,FieldMaterialNumberOfComponents,Err)  
  CALL CMISSFieldComponentInterpolationSet(MaterialField,CMISSFieldUVariableType,1,CMISSFieldConstantInterpolation,Err)
  CALL CMISSFieldComponentInterpolationSet(MaterialField,CMISSFieldUVariableType,2,CMISSFieldConstantInterpolation,Err)
  CALL CMISSFieldCreateFinish(MaterialField,Err)

  !Set Mooney-Rivlin constants c10 and c01 to 2.0 and 6.0 respectively.
  CALL CMISSFieldComponentValuesInitialise(MaterialField,CMISSFieldUVariableType,CMISSFieldValuesSetType,1,C1,Err)
  CALL CMISSFieldComponentValuesInitialise(MaterialField,CMISSFieldUVariableType,CMISSFieldValuesSetType,2,C2,Err)

  !Create the equations_set
  CALL CMISSFieldTypeInitialise(EquationsSetField,Err)
  CALL CMISSEquationsSetTypeInitialise(EquationsSet,Err)
  CALL CMISSEquationsSetCreateStart(EquationSetUserNumber,Region,FibreField,CMISSEquationsSetElasticityClass, &
    & CMISSEquationsSetFiniteElasticityType,CMISSEquationsSetMooneyRivlinSubtype,EquationsSetFieldUserNumber,EquationsSetField,&
    & EquationsSet,Err)
  CALL CMISSEquationsSetCreateFinish(EquationsSet,Err)

  !Create the dependent field with 2 variables and 4 components (3 displacement, 1 pressure)
  CALL CMISSFieldTypeInitialise(DependentField,Err)
  CALL CMISSFieldCreateStart(FieldDependentUserNumber,Region,DependentField,Err)
  CALL CMISSFieldTypeSet(DependentField,CMISSFieldGeneralType,Err)
  CALL CMISSFieldMeshDecompositionSet(DependentField,Decomposition,Err)
  CALL CMISSFieldGeometricFieldSet(DependentField,GeometricField,Err)
  CALL CMISSFieldDependentTypeSet(DependentField,CMISSFieldDependentType,Err)
  CALL CMISSFieldNumberOfVariablesSet(DependentField,FieldDependentNumberOfVariables,Err)
  CALL CMISSFieldNumberOfComponentsSet(DependentField,CMISSFieldUVariableType,FieldDependentNumberOfComponents,Err)
  CALL CMISSFieldNumberOfComponentsSet(DependentField,CMISSFieldDelUDelNVariableType,FieldDependentNumberOfComponents,Err)
  CALL CMISSFieldComponentMeshComponentSet(DependentField,CMISSFieldUVariableType,1,DisplacementMeshComponentNumber,Err)
  CALL CMISSFieldComponentMeshComponentSet(DependentField,CMISSFieldUVariableType,2,DisplacementMeshComponentNumber,Err)
  CALL CMISSFieldComponentMeshComponentSet(DependentField,CMISSFieldUVariableType,3,DisplacementMeshComponentNumber,Err)
  CALL CMISSFieldComponentMeshComponentSet(DependentField,CMISSFieldUVariableType,4,PressureMeshComponentNumber,Err)
  CALL CMISSFieldComponentMeshComponentSet(DependentField,CMISSFieldDelUDelNVariableType,1,DisplacementMeshComponentNumber,Err)
  CALL CMISSFieldComponentMeshComponentSet(DependentField,CMISSFieldDelUDelNVariableType,2,DisplacementMeshComponentNumber,Err)
  CALL CMISSFieldComponentMeshComponentSet(DependentField,CMISSFieldDelUDelNVariableType,3,DisplacementMeshComponentNumber,Err)
  CALL CMISSFieldComponentMeshComponentSet(DependentField,CMISSFieldDelUDelNVariableType,4,PressureMeshComponentNumber,Err)
  CALL CMISSFieldScalingTypeSet(DependentField,CMISSFieldUnitScaling,Err)
  CALL CMISSFieldCreateFinish(DependentField,Err)

  CALL CMISSEquationsSetDependentCreateStart(EquationsSet,FieldDependentUserNumber,DependentField,Err)
  CALL CMISSEquationsSetDependentCreateFinish(EquationsSet,Err)

  CALL CMISSEquationsSetMaterialsCreateStart(EquationsSet,FieldMaterialUserNumber,MaterialField,Err)  
  CALL CMISSEquationsSetMaterialsCreateFinish(EquationsSet,Err)

  IF(TRIM(ARG_LEVEL)=="2".OR.TRIM(ARG_LEVEL)=="3") THEN
    !Set up analytic field
    CALL CMISSFieldTypeInitialise(AnalyticField,Err)
    CALL CMISSEquationsSetAnalyticCreateStart(EquationsSet,CMISSEquationsSetFiniteElasticityCylinder, &
      & FieldAnalyticUserNumber,AnalyticField,Err)
    !Finish the equations set analytic field variables
    CALL CMISSEquationsSetAnalyticCreateFinish(EquationsSet,Err)

    !Set the analytic parameters
    CALL CMISSEquationsSetAnalyticUserParamSet(EquationsSet,CMISSFiniteElasticityAnalyticCylinderParamPinIdx,INNER_PRESSURE,Err)
    CALL CMISSEquationsSetAnalyticUserParamSet(EquationsSet,CMISSFiniteElasticityAnalyticCylinderParamPoutIdx,OUTER_PRESSURE,Err)
    CALL CMISSEquationsSetAnalyticUserParamSet(EquationsSet,CMISSFiniteElasticityAnalyticCylinderParamLambdaIdx,LAMBDA,Err)
    CALL CMISSEquationsSetAnalyticUserParamSet(EquationsSet,CMISSFiniteElasticityAnalyticCylinderParamTsiIdx,TSI,Err)
    CALL CMISSEquationsSetAnalyticUserParamSet(EquationsSet,CMISSFiniteElasticityAnalyticCylinderParamRinIdx,INNER_RAD,Err)
    CALL CMISSEquationsSetAnalyticUserParamSet(EquationsSet,CMISSFiniteElasticityAnalyticCylinderParamRoutIdx,OUTER_RAD,Err)
    CALL CMISSEquationsSetAnalyticUserParamSet(EquationsSet,CMISSFiniteElasticityAnalyticCylinderParamC1Idx,C1,Err)
    CALL CMISSEquationsSetAnalyticUserParamSet(EquationsSet,CMISSFiniteElasticityAnalyticCylinderParamC2Idx,C2,Err)
  ENDIF

  !Create the equations set equations
  CALL CMISSEquationsTypeInitialise(Equations,Err)
  CALL CMISSEquationsSetEquationsCreateStart(EquationsSet,Equations,Err)
  CALL CMISSEquationsSparsityTypeSet(Equations,CMISSEquationsSparseMatrices,Err)
  CALL CMISSEquationsOutputTypeSet(Equations,CMISSEquationsNoOutput,Err)
  CALL CMISSEquationsSetEquationsCreateFinish(EquationsSet,Err)

  !Initialise dependent field from undeformed geometry and displacement bcs and set hydrostatic pressure
  CALL CMISSFieldParametersToFieldParametersComponentCopy(GeometricField,CMISSFieldUVariableType,CMISSFieldValuesSetType, &
    & 1,DependentField,CMISSFieldUVariableType,CMISSFieldValuesSetType,1,Err)
  CALL CMISSFieldParametersToFieldParametersComponentCopy(GeometricField,CMISSFieldUVariableType,CMISSFieldValuesSetType, &
    & 2,DependentField,CMISSFieldUVariableType,CMISSFieldValuesSetType,2,Err)
  CALL CMISSFieldParametersToFieldParametersComponentCopy(GeometricField,CMISSFieldUVariableType,CMISSFieldValuesSetType, &
    & 3,DependentField,CMISSFieldUVariableType,CMISSFieldValuesSetType,3,Err)
  CALL CMISSFieldComponentValuesInitialise(DependentField,CMISSFieldUVariableType,CMISSFieldValuesSetType,4,-14.0_CMISSDP,Err)

  !Set the bc using the analytic solution routine
  IF(TRIM(ARG_LEVEL)=="2".OR.TRIM(ARG_LEVEL)=="3") THEN
    CALL CMISSEquationsSetBoundaryConditionsAnalytic(EquationsSet,Err)
  ELSE
    !Set BC manually
    !Prescribe boundary conditions (absolute nodal parameters)
    CALL CMISSBoundaryConditionsTypeInitialise(BoundaryConditions,Err)
    CALL CMISSEquationsSetBoundaryConditionsCreateStart(EquationsSet,BoundaryConditions,Err)

    !Get surfaces - will fix two nodes on bottom face, pressure conditions inside
    CALL CMISSGeneratedMeshSurfaceGet(GeneratedMesh,CMISSGeneratedMeshCylinderTopSurfaceType,TopSurfaceNodes,TopNormalXi,Err)
    CALL CMISSGeneratedMeshSurfaceGet(GeneratedMesh,CMISSGeneratedMeshCylinderBottomSurfaceType,BottomSurfaceNodes, &
      & BottomNormalXi,Err)
    CALL CMISSGeneratedMeshSurfaceGet(GeneratedMesh,CMISSGeneratedMeshCylinderInnerSurfaceType,InnerSurfaceNodes,InnerNormalXi,Err)
    CALL CMISSGeneratedMeshSurfaceGet(GeneratedMesh,CMISSGeneratedMeshCylinderOuterSurfaceType,OuterSurfaceNodes,OuterNormalXi,Err)

    !Set all inner surface nodes to inner pressure
    DO NN=1,SIZE(InnerSurfaceNodes,1)
      CALL CMISSBoundaryConditionsSetNode(BoundaryConditions,CMISSFieldDelUDelNVariableType,1,1,InnerSurfaceNodes(NN), &
        & abs(InnerNormalXi),CMISSBoundaryConditionPressureIncremented,INNER_PRESSURE,Err)   ! INNER_PRESSURE
      IF(Err/=0) WRITE(*,*) "ERROR WHILE ASSIGNING INNER PRESSURE TO NODE", InnerSurfaceNodes(NN)
    ENDDO

    !Set all outer surface nodes to outer pressure
    DO NN=1,SIZE(OuterSurfaceNodes,1)
      CALL CMISSBoundaryConditionsSetNode(BoundaryConditions,CMISSFieldDelUDelNVariableType,1,1,OuterSurfaceNodes(NN), &
        & abs(OuterNormalXi),CMISSBoundaryConditionPressureIncremented,OUTER_PRESSURE,Err)
      IF(Err/=0) WRITE(*,*) "ERROR WHILE ASSIGNING OUTER PRESSURE TO NODE", OuterSurfaceNodes(NN)
    ENDDO

    !Set all top nodes fixed in z plane at the set height
    deformedHeight=HEIGHT*LAMBDA
    DO NN=1,SIZE(TopSurfaceNodes,1)
      CALL CMISSBoundaryConditionsSetNode(BoundaryConditions,CMISSFieldUVariableType,1,1,TopSurfaceNodes(NN), &
        & 3,CMISSBoundaryConditionFixed,deformedHeight,Err)
      IF(Err/=0) WRITE(*,*) "ERROR WHILE ASSIGNING FIXED CONDITION TO NODE", TopSurfaceNodes(NN)
    ENDDO

    !Set all bottom nodes fixed in z plane
    DO NN=1,SIZE(BottomSurfaceNodes,1)
      CALL CMISSBoundaryConditionsSetNode(BoundaryConditions,CMISSFieldUVariableType,1,1,BottomSurfaceNodes(NN), &
        & 3,CMISSBoundaryConditionFixed,0.0_CMISSDP,Err)
      IF(Err/=0) WRITE(*,*) "ERROR WHILE ASSIGNING FIXED CONDITION TO NODE", BottomSurfaceNodes(NN)
    ENDDO

    !Set two nodes on the bottom surface to axial displacement only
    X_FIXED=.FALSE.
    Y_FIXED=.FALSE.
    DO NN=1,SIZE(BottomSurfaceNodes,1)
      CALL CMISSFieldParameterSetGetNode(GeometricField,CMISSFieldUVariableType,CMISSFieldValuesSetType,1, &
        & 1,BottomSurfaceNodes(NN),1,xValue,Err)
      IF(abs(xValue)<1e-5_CMISSDP) THEN
        !Constrain it in x direction
        CALL CMISSBoundaryConditionsSetNode(BoundaryConditions,CMISSFieldUVariableType,1,1,BottomSurfaceNodes(NN),1, &
          & CMISSBoundaryConditionFixed,0.0_CMISSDP,Err)
        X_FIXED=.TRUE.
      ENDIF
      CALL CMISSFieldParameterSetGetNode(GeometricField,CMISSFieldUVariableType,CMISSFieldValuesSetType,1, &
        & 1,BottomSurfaceNodes(NN),2,yValue,Err)
      IF(abs(yValue)<1e-5_CMISSDP) THEN
        !Constrain it in y direction
        CALL CMISSBoundaryConditionsSetNode(BoundaryConditions,CMISSFieldUVariableType,1,1,BottomSurfaceNodes(NN),2, &
          & CMISSBoundaryConditionFixed,0.0_CMISSDP,Err)
        Y_FIXED=.TRUE.
      ENDIF
    ENDDO
    !Check
    CALL MPI_REDUCE(X_FIXED,X_OKAY,1,MPI_LOGICAL,MPI_LOR,0,MPI_COMM_WORLD,MPI_IERROR)
    CALL MPI_REDUCE(Y_FIXED,Y_OKAY,1,MPI_LOGICAL,MPI_LOR,0,MPI_COMM_WORLD,MPI_IERROR)
    IF(ComputationalNodeNumber==0) THEN
      IF(.NOT.(X_OKAY.AND.Y_OKAY)) THEN
        WRITE(*,*) "Could not fix nodes to prevent rigid body motion"
        STOP
      ENDIF
    ENDIF
    CALL CMISSEquationsSetBoundaryConditionsCreateFinish(EquationsSet,Err)
  ENDIF

  !Define the problem
  CALL CMISSProblemTypeInitialise(Problem,Err)
  CALL CMISSProblemCreateStart(ProblemUserNumber,Problem,Err)
  CALL CMISSProblemSpecificationSet(Problem,CMISSProblemElasticityClass,CMISSProblemFiniteElasticityType, &
    & CMISSProblemNoSubtype,Err)
  CALL CMISSProblemCreateFinish(Problem,Err)

  !Create the problem control loop
  CALL CMISSProblemControlLoopCreateStart(Problem,Err)
  CALL CMISSControlLoopTypeInitialise(ControlLoop,Err)
  CALL CMISSProblemControlLoopGet(Problem,CMISSControlLoopNode,ControlLoop,Err)
  CALL CMISSControlLoopMaximumIterationsSet(ControlLoop,3,Err)  ! this one sets the increment loop counter
  CALL CMISSProblemControlLoopCreateFinish(Problem,Err)
  
  !Create the problem solvers
  CALL CMISSSolverTypeInitialise(Solver,Err)
  CALL CMISSSolverTypeInitialise(LinearSolver,Err)
  CALL CMISSProblemSolversCreateStart(Problem,Err)
  CALL CMISSProblemSolverGet(Problem,CMISSControlLoopNode,1,Solver,Err)
  CALL CMISSSolverOutputTypeSet(Solver,CMISSSolverProgressOutput,Err)
  !CALL CMISSSolverNewtonJacobianCalculationTypeSet(Solver,CMISSSolverNewtonJacobianFDCalculated,Err)  !Slower
  CALL CMISSSolverNewtonJacobianCalculationTypeSet(Solver,CMISSSolverNewtonJacobianAnalyticCalculated,Err)
  CALL CMISSSolverNewtonLinearSolverGet(Solver,LinearSolver,Err)
  CALL CMISSSolverNewtonLineSearchTypeSet(Solver,CMISSSolverNewtonLinesearchQuadratic,Err) !Helps convergence with cubics...
  CALL CMISSSolverLinearTypeSet(LinearSolver,CMISSSolverLinearDirectSolveType,Err)
  CALL CMISSProblemSolversCreateFinish(Problem,Err)

  !Create the problem solver equations
  CALL CMISSSolverTypeInitialise(Solver,Err)
  CALL CMISSSolverEquationsTypeInitialise(SolverEquations,Err)
  CALL CMISSProblemSolverEquationsCreateStart(Problem,Err)   
  CALL CMISSProblemSolverGet(Problem,CMISSControlLoopNode,1,Solver,Err)
  CALL CMISSSolverSolverEquationsGet(Solver,SolverEquations,Err)
  CALL CMISSSolverEquationsSparsityTypeSet(SolverEquations,CMISSSolverEquationsSparseMatrices,Err)
  CALL CMISSSolverEquationsEquationsSetAdd(SolverEquations,EquationsSet,EquationsSetIndex,Err)
  CALL CMISSProblemSolverEquationsCreateFinish(Problem,Err)

  !Solve problem
  CALL CMISSProblemSolve(Problem,Err)

  !Output Analytic analysis
  IF(TRIM(ARG_LEVEL)=="2".OR.TRIM(ARG_LEVEL)=="3") THEN
    Call CMISSAnalyticAnalysisOutput(DependentField,"output/testingPoints",Err)
  ENDIF

  !Output solution  
  CALL CMISSFieldsTypeInitialise(Fields,Err)
  CALL CMISSFieldsTypeCreate(Region,Fields,Err)
  CALL CMISSFieldIONodesExport(Fields,"output/testingPoints","FORTRAN",Err)
  CALL CMISSFieldIOElementsExport(Fields,"output/testingPoints","FORTRAN",Err)
  CALL CMISSFieldsTypeFinalise(Fields,Err)

  CALL CMISSFinalise(Err)

  WRITE(*,'(A)') "Program successfully completed."

  STOP


  CONTAINS

  !> Returns the argument of the requested type as a varying string
  SUBROUTINE GET_ARGUMENT(ARG_TYPE,ARG)
    CHARACTER(LEN=*), INTENT(IN) :: ARG_TYPE
    CHARACTER(LEN=256), INTENT(OUT) :: ARG
    !Local variables
    CHARACTER(LEN=LEN_TRIM(ARG_TYPE)) :: ARG_TYPE_UPPER
    CHARACTER(LEN=256) :: WORD,WORD_UPPER,ARGOUT
    INTEGER(CMISSIntg) :: NARGS,I,LENG,WORD_LENG

    NARGS=iargc()
    LENG=LEN_TRIM(ARG_TYPE) !STRING TO LOOK FOR
    CALL UPPER_CASE(ARG_TYPE,ARG_TYPE_UPPER)
    ARG=""
    
    DO I=1,NARGS
      CALL GETARG(I,WORD)
      CALL UPPER_CASE(WORD,WORD_UPPER)
      WORD_LENG=LEN_TRIM(WORD_UPPER)
      IF(WORD_UPPER(1:1+LENG)=="-"//TRIM(ARG_TYPE_UPPER)) THEN
        IF(WORD_UPPER(2+LENG:2+LENG)=="=") THEN
          ! USING = AS DELIMITER
          ARGOUT=WORD(3+LENG:WORD_LENG)
        ELSE
          ! USING A SPACE AS DELIMITER
          CALL GETARG(I+1,ARGOUT)
        ENDIF
      ENDIF
    ENDDO

    CALL UPPER_CASE(ARGOUT,ARG)

  END SUBROUTINE GET_ARGUMENT

  !> Convert a string to lower case
  SUBROUTINE LOWER_CASE(UWORD,LWORD)
    CHARACTER(LEN=*),INTENT(IN) :: UWORD
    CHARACTER(LEN=LEN(UWORD)),INTENT(OUT) :: LWORD
    INTEGER(CMISSIntg) ::I,IC,NLEN

    NLEN = LEN_TRIM(UWORD)
    LWORD=UWORD
    DO I=1,NLEN
      IC = ICHAR(UWORD(I:I))
      IF (IC >= 65 .and. IC <= 90) LWORD(I:I) = CHAR(IC+32)
    ENDDO
  END SUBROUTINE LOWER_CASE

  !> Converts a string to upper case
  SUBROUTINE UPPER_CASE(LWORD,UWORD)
    CHARACTER(LEN=*),INTENT(IN) :: LWORD
    CHARACTER(LEN=LEN(LWORD)),INTENT(OUT) :: UWORD
    INTEGER(CMISSIntg) ::I,IC,NLEN

    NLEN = LEN_TRIM(LWORD)
    UWORD=LWORD
    DO I=1,NLEN
      IC = ICHAR(LWORD(I:I))
      IF (IC >= 97 .and. IC <= 122) UWORD(I:I) = CHAR(IC-32)
    ENDDO
  END SUBROUTINE UPPER_CASE

END PROGRAM TESTINGPOINTSEXAMPLE
