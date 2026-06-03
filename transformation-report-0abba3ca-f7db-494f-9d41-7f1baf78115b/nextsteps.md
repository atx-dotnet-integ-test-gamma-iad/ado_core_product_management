# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this is consistent with any dependent or consuming projects in the solution.

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not block the build.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior has not changed after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between the legacy .NET Framework and the new .NET runtime.

## 4. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to scan for any APIs that may compile successfully but fail at runtime on non-Windows platforms, if cross-platform support is a goal.

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze
```

Pay particular attention to usage of:
- `System.Windows.Forms` or `System.Web` (not supported cross-platform)
- Registry access (`Microsoft.Win32.Registry`)
- COM interop or P/Invoke calls

## 5. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` have versions compatible with your target framework. Look for packages that still target `net45` or `netstandard1.x`, as these may have updated versions with better compatibility.

```bash
dotnet list package --outdated
```

Update packages where appropriate:

```bash
dotnet add package <PackageName> --version <NewVersion>
```

## 6. Validate Configuration Files

If the project previously relied on `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or equivalent .NET configuration mechanisms. The legacy XML-based configuration system has limited support in modern .NET.

## 7. Perform Runtime Validation

Run the application in a staging or local environment and exercise the primary workflows to confirm end-to-end functionality. Compare outputs against the legacy version where possible to identify any behavioral regressions.

## 8. Publish the Application

Once validation is complete, publish the application using the following command:

```bash
dotnet publish --configuration Release --output ./publish
```

If a self-contained deployment is required (no .NET runtime pre-installed on the target machine):

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier for your target environment (e.g., `linux-x64`, `osx-x64`).