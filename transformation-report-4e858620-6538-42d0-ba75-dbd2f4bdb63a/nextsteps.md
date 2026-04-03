# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

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

Ensure there are no warnings that could indicate deprecated APIs or compatibility issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review the output for any failing tests or unexpected behavior that may have been introduced during the migration.

## 4. Check for Runtime Compatibility Issues

Even with a clean build, runtime issues can exist. Pay attention to the following:

- **Reflection-based code**: APIs around `System.Reflection` may behave differently on cross-platform .NET.
- **Platform-specific APIs**: Any usage of Windows-only APIs (e.g., registry access, COM interop, `System.Drawing`) will throw `PlatformNotSupportedException` on non-Windows systems. Search the codebase for such usages.
- **Configuration files**: Ensure `app.config` or `web.config` settings have been migrated to `appsettings.json` or equivalent if applicable.

## 5. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` support the target framework. You can inspect this with:

```bash
dotnet list package --outdated
```

Replace any packages that do not support the target framework with their modern equivalents.

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a build.

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier for your target environment (e.g., `win-x64`, `osx-x64`).

## 8. Verify Output Artifacts

After publishing, navigate to the output directory and confirm the expected binaries and configuration files are present before deploying to the target environment.