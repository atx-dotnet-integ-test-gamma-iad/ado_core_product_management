# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional for multi-targeting.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding.

### 4. Check NuGet Package Compatibility
Review all NuGet dependencies in each `.csproj` file. Confirm that every package has a version compatible with the target .NET version. You can use the following command to check for outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions compatible with your target framework.

### 5. Audit for Removed or Changed APIs
Run the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.ApiCompat` tooling to surface any API usage that may compile but behave differently at runtime on cross-platform .NET:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <solution>.sln
```

Pay particular attention to:
- `System.Windows.Forms` or `System.Web` references, which are not cross-platform.
- P/Invoke calls that may behave differently on Linux or macOS.
- File path handling that assumes Windows-style separators.

### 6. Test on Target Platforms
If cross-platform support (Linux, macOS) is a goal, build and run the application on each target operating system to surface any platform-specific runtime issues that would not appear during a Windows build.

### 7. Publish the Application
Once validation is complete, produce a release build using the appropriate publish profile:

```bash
dotnet publish --configuration Release --runtime <target-rid> --self-contained true
```

Replace `<target-rid>` with the appropriate Runtime Identifier, for example:
- `win-x64`
- `linux-x64`
- `osx-x64`

Review the publish output directory to confirm all required assets are present before deploying.