# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

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

Ensure there are no warnings that could indicate compatibility issues with migrated NuGet packages or APIs.

## 3. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` are compatible with your target framework. You can inspect this with:

```bash
dotnet list package --outdated
dotnet list package --deprecated
```

Update any outdated or deprecated packages to their latest stable, cross-platform compatible versions.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between .NET Framework and modern .NET (e.g., changes in `System.Data`, threading, or serialization behavior).

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer to identify any remaining Windows-specific or platform-specific API calls that may not behave correctly on Linux or macOS:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Address any reported `CA1416` (platform compatibility) warnings in the build output.

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) to confirm consistent behavior:

```bash
dotnet run --configuration Release
```

Pay particular attention to:
- File path handling (`Path.Combine` vs hardcoded separators)
- Environment variable access
- Registry access (Windows-only; must be abstracted or removed for cross-platform use)
- Any use of `System.Windows` or WinForms/WPF namespaces if this is a library

## 7. Publish a Release Build

Once validation is complete, publish the application for your target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate Runtime Identifier (RID) for your deployment target (e.g., `win-x64`, `osx-x64`, `linux-arm64`). Review the contents of the `publish` output folder to confirm all required assets are present.