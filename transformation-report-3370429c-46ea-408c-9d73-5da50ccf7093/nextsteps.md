# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine by running:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly against the new target framework:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not fully support the target framework.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types or obsolete APIs, as these can indicate future compatibility issues.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review the test results and investigate any failures. Failures at this stage often indicate runtime behavioral differences between .NET Framework and cross-platform .NET that were not caught at compile time.

## 5. Check for Windows-Specific API Usage

Even when a project builds successfully, it may contain APIs that only function on Windows. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Rebuild and review any new analyzer warnings. Common problem areas include:
- `System.Data` with OLE DB or ODBC providers
- `Microsoft.Win32` registry access
- Windows-specific file path assumptions

## 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (Linux, macOS) to catch any platform-specific runtime issues that static analysis may not surface.

## 7. Review `AdoCore.csproj` for Legacy Artifacts

Open the project file and check for any remaining legacy MSBuild elements that may have carried over from the old format, such as:

- Explicit `<Compile>` or `<None>` entries that are redundant in SDK-style projects
- References to `packages.config` instead of `PackageReference`
- Leftover `<HintPath>` elements pointing to local `packages` folders

Remove or update these as needed to keep the project file clean.

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier for your target environment (`win-x64`, `osx-x64`, etc.). Review the output directory to confirm all required assets are present before deploying.