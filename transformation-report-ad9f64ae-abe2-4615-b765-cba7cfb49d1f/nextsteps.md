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

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Removed or Changed APIs

Even without build errors, some .NET Framework APIs behave differently or have been removed in cross-platform .NET. Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` compatibility shims if needed.

Run the compatibility analyzer:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <path-to-solution>
```

## 5. Validate Platform-Specific Behavior

Since this is a cross-platform migration, test the application on each target operating system (Windows, Linux, macOS) if applicable. Pay particular attention to:

- File path separators (`\` vs `/`)
- Registry access (not available on Linux/macOS)
- Windows-specific APIs such as `System.Drawing` or `Microsoft.Win32`

## 6. Review NuGet Package Compatibility

Confirm all NuGet dependencies support the target framework. Run:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions compatible with your target framework.

## 7. Validate Runtime Output

Execute the application and perform functional testing against expected inputs and outputs. Compare results with the legacy .NET Framework version to confirm behavioral parity.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment (no runtime dependency on the target machine):

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (`linux-x64`, `osx-x64`, etc.) as needed.

## 9. Review Published Output

Inspect the `./publish` directory to confirm all expected files, configuration files, and assets are present before deploying to the target environment.