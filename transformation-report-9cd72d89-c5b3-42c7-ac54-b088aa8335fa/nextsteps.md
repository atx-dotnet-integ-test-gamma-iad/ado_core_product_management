# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`). Example:

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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Review NuGet Package Versions

Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework, particularly any that were previously targeting `.NET Framework`.

## 4. Check for Removed or Changed APIs

Review any usages of APIs that are known to be unavailable or changed in cross-platform .NET, such as:

- `System.Web` (not available outside of ASP.NET Core)
- `AppDomain`
- `BinaryFormatter`
- Windows-specific registry or COM interop calls

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package if needed.

## 5. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between .NET Framework and modern .NET.

## 6. Validate Cross-Platform Behavior

If cross-platform support is a goal, run the application on each target operating system (Windows, Linux, macOS) to identify any platform-specific issues that would not surface during a Windows-only build.

```bash
dotnet run --configuration Release
```

Pay particular attention to:

- File path separators (`\` vs `/`)
- Case sensitivity in file system operations
- Platform-specific environment variables

## 7. Review Runtime Configuration Files

Check for the presence and correctness of the following files:

- `appsettings.json` (for configuration)
- `runtimeconfig.json` (auto-generated, but verify if manually edited)
- `launchSettings.json` (for local development profiles)

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment target. A full list of runtime identifiers is available in the [Microsoft RID catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).