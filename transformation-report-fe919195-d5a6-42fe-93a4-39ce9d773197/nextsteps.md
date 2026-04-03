# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

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

Ensure there are no warnings that could indicate deprecated APIs or compatibility shims that may cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify functional correctness:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs that compiled successfully may behave differently or throw at runtime on non-Windows platforms. Review the code for usage of:

- `System.Windows.Forms` or `System.Drawing` (GDI+)
- `Microsoft.Win32` registry access
- COM interop or P/Invoke calls targeting Windows-only native libraries
- `AppDomain` usage that is unsupported in .NET Core and later

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package to identify remaining platform-specific concerns.

## 5. Validate NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` have versions that support your target framework. Run:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with cross-platform support.

## 6. Run the Application on Target Platforms

Execute the application on each platform you intend to support (Windows, Linux, macOS) and verify runtime behavior:

```bash
dotnet run --configuration Release
```

Pay attention to file path separators, environment variable access, and any platform-specific configuration loading.

## 7. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent build as appropriate for your deployment target.

**Framework-dependent:**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish/linux-x64
```

**Self-contained (example for Windows x64):**
```bash
dotnet publish -c Release -r win-x64 --self-contained true -o ./publish/win-x64
```

Review the contents of the output directory to confirm all required assemblies and configuration files are present before deploying to the target environment.